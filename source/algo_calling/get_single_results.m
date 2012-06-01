function [ys, censoreds, runtimes, runlengths, solveds, best_sols] = get_single_results(func, Theta_idx, seeds, instance_filenames, censorLimits)
%=== Returns the performance (e.g. runtime/runlength) of the algorithm for the parameter configurations indexed by Theta_idx on the given instances with the given seeds.
%=== Always call a script via the command line that executes the runs.
if nargin < 5
    error 'need 5 arguments' 
end

global files_to_delete;
files_to_delete = {};

onCleanup(@()delete_files());

numTry = 1;
while 1
    try % watch out for any exception from calling the target algorithm.
        [solveds, censoreds, runtimes, runlengths, best_sols] = startRunsInBatch(func, Theta_idx, instance_filenames, seeds, censorLimits);
        runtimes = min(runtimes, 1e7); % don't count wrong answers as infinity.
        break;
    catch ME
        bout(['Num try: ', num2str(numTry), '\n']);
        bout(ME.message);
        for i=1:length(ME.stack)
            bout(['In method ', parsePath(ME.stack(i).file, '.'), ' at line ', num2str(ME.stack(i).line), '\n']);
        end
        numTry = numTry+1;
        if numTry >= 20
            delete_files();
            func
            error('Still not successful after 20 tries.');
        end
    end
end

global runTimeForRunningAlgo;
assert(all(runtimes >= -1e-5));
actual_runtimes = min([censorLimits'; runtimes'], [], 1); % to deal with inf in runs with wrong answer
runTimeForRunningAlgo = runTimeForRunningAlgo + sum(actual_runtimes);

switch func.singleRunObjective
    case 'runtime'
        ys = runtimes;
    case 'runlength'    
        ys = runlengths;
    case 'solqual'
        ys = best_sols;
        censoreds = zeros(size(ys,1),1);
    otherwise 
        error 'Still have to implement objective functions for single algorithm runs other than runtime, runlength, and solqual.'
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% HELPER FUNCTIONS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [solveds, censoreds, runtimes, runlengths, best_sols] = startRunsInBatch(func, Theta_idx, instance_filenames, seeds, censorLimits)
%=== This starts a batch of runs, parses the results and returns them.
results = startManyRuns(func, Theta_idx, instance_filenames, seeds, censorLimits);
solveds = -ones(length(seeds),1);
censoreds = -ones(length(seeds),1);
runtimes = -ones(length(seeds),1);
solveds = -ones(length(seeds),1);
runlengths = -ones(length(seeds),1);
best_sols = -ones(length(seeds),1);

for i=1:length(seeds)
    res = results(i,:);
    seed_out = res(end);    
    assert(seeds(i) == seed_out, 'must report the correct seed');

    solved = res(end-4);
    if res(end-3) > censorLimits(i)
        solved = 0;
        censoreds(i) = 1;
    end
    solveds(i) = solved;

    if solved == 3 % wrong answer!
        warnstring = strcat(['Wrong answer for theta_idx ', num2str(Theta_idx(i)), ', instance ', instance_filenames{i}, ', and seed ', num2str(seeds(i)), '.\n']);
        warning(warnstring);
        bout(warnstring);

        censoreds(i) = 0;
        runtimes(i) = inf;
        runlengths(i) = inf;
        best_sols(i) = inf;
    else
        if solved == 0 % TIMEOUT
            censoreds(i) = 1;
        else
            censoreds(i) = 0;
        end
        if func.force_runtime_cap_at_limit
            runtimes(i) = min(res(end-3), censorLimits(i)); 
        else
            runtimes(i) = res(end-3);
        end
        runlengths(i) = res(end-2);
        best_sols(i) = res(end-1);
    end
end
delete_files();


function delete_files()
%=== Clean up files in directory RUNFILES - can't do earlier due to weird
%=== error (probably since Matlab is looking ahead, executing the delete
%=== too early?)
global files_to_delete
for i=1:length(files_to_delete)
    fprintf(strcat('Deleting file: ', files_to_delete{i}, '\n'));
    delete(files_to_delete{i});
end
files_to_delete = {};

function res = startManyRuns(func, Theta_idx, instance_filenames, seeds, censorLimits) 
% Don't want to rewrite all the functionality of adding inst_id,
% algo_config_id (!) and algorun_config_id to the database.
% Rather use the existing ruby scripts to do that, we only use
% Matlab for queries: simply write a file where each line is a
% call to single_runstarter.rb
env = func.env;
global allParamStrings;

%=== Create file with commands to run.
s = rand('state');
for openTry=1:10
    file_with_cmds = parsePath(tempname, '.');
    
    cmds_fid = fopen(file_with_cmds,'w');
    if cmds_fid ~= -1 
        break
    end
    bout(['Try ', num2str(openTry), ' failed to open file: ', file_with_cmds, '\n']);
    if openTry == 10
        delete_files();
        errstr = ['Cannot open file to write callstrings to: ', file_with_cmds, '\n'];
        error(errstr);
    end
end
rand('state', s);

outfile = parsePath(tempname, '.');

%=== Run the commands in the file.
fprintf(cmds_fid, strcat([env.executable, '\n', env.exec_path, '\n', env.params_filename, '\n', num2str(-1), '\n']));

global TestTheta;
for i=1:length(Theta_idx)
    %=== Construct param_string.
    theta_idx = Theta_idx(i);
    if theta_idx < 0
        param_string = alphabeticalParameterString(func, TestTheta(-theta_idx,:));
    else
        param_string = allParamStrings{theta_idx};
    end
    fprintf(cmds_fid, strcat([instance_filenames{i}, ' ', num2str(seeds(i)), ' ', num2str(censorLimits(i)), ' ', param_string, '\n']));
end
try
    fclose(cmds_fid); % throws error if we're deleting the file after.
catch ME
    bout(strcat(['Cannot close cmds_fid: ', num2str(cmds_fid), ' for file ', file_with_cmds]));
end

run_cmd = strcat(['ruby scripts/al_run_configs_in_file_nodb.rb ', file_with_cmds]);
run_cmd = strcat([run_cmd, ' ', outfile]);
    
connect_cmd = strcat(['cd ' func.rootdir '; ']);
cmd = [connect_cmd ' ' run_cmd]
unix(cmd);

res = csvread(outfile);

global files_to_delete;
files_to_delete = [files_to_delete, {file_with_cmds, outfile}];
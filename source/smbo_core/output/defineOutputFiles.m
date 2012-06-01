function [workspace_savedir, paramdir, options, workspace_filename_for_complete_run] = defineOutputFiles(options, func, numRun)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRUCT FILENAMES FOR SAVING LOG FILES ETC.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
paramString = '';
if ~strcmp(options.method, 'al')
    paramString = strcat(options.method, '-');
end
paramString = strcat([paramString, options.modelType]);
switch options.modelType
    case 'rf'
        paramString = strcat([paramString, 'nSub', num2str(options.nSub), 'pars', num2str(options.split_ratio_init), '_', num2str(options.Splitmin_init)]);
        if options.orig_rf==1
            paramString = strcat([paramString, 'RFo']);
        end
    case 'GPML'
        paramString = strcat([paramString, '-tSS', num2str(options.trainSubSize)]);
end
paramString = strcat([paramString, '-logM', num2str(options.logModel)]);

paramString = strcat([paramString, 'eiI', num2str(options.ei_inc), 'ei', num2str(options.expImpCriterion) ]);
paramString = strcat([paramString, 'nLS', num2str(options.numLSbest), 'rR', num2str(options.numRandomInEiOpt) ]);

paramString = strcat([paramString, 'iS', num2str(options.intens_schedule)]);
paramString = strcat([paramString, 'ac', num2str(options.adaptive_capping)]);
paramString = strcat([paramString, 'rF', num2str(options.frac_rawruntime)]);
paramString = strcat([paramString, 'cs', num2str(options.cap_slack)]);
if options.onlyOneChallenger
    paramString = strcat([paramString, '-1chal']);
end    
if options.valid
    paramString = [paramString, '-valid'];
end
if isfield(options, 'outputFolderSuffix')
    paramString = [paramString, options.outputFolderSuffix];
end

%=== Define bookkeeping variables as global for convenient use in subfunctions.
if ~exist(func.outdir, 'dir')
    mkdir(func.outdir);
end

if isfield(options, 'final_outdir')
    paramdir = options.final_outdir;
else
    if ~isempty(options.experiment_name)
        experimentDir = parsePath(options.experiment_name, func.outdir);
    else
        experimentDir = parsePath('UNTITLED_EXPERIMENTS/', func.outdir);
    end
    if ~exist(experimentDir, 'dir')
        mkdir(experimentDir);
    end
    paramdir = parsePath([func.name, '-', paramString], experimentDir);
end
cmd = ['mkdir -p ', paramdir];
system(cmd);
% if ~exist(paramdir, 'dir')
%     mkdir(paramdir);
% end

resfilename = parsePath(['res', num2str(numRun), '.txt'], paramdir);
logfilename = parsePath(['l-r', num2str(numRun), '.txt'], paramdir);

trajfilename = parsePath(['traj-algo-overallobj', options.overallobj, '-time', num2str(options.kappa_max) ,'-',num2str(numRun), '.txt'], paramdir);
detailed_trajfilename = parsePath(['det_traj-algo-overallobj', options.overallobj, '-time', num2str(options.kappa_max) ,'-',num2str(numRun), '.txt'], paramdir);
options.val_filename = parsePath(['overallobj', options.overallobj, '-time', num2str(options.kappa_max) ,'-',num2str(numRun), '.val'], paramdir);
options.valall_filename = parsePath(['overallobj', options.overallobj, '-time', num2str(options.kappa_max) ,'-all',num2str(numRun), '.val'], paramdir);
workspace_savedir = parsePath(['run', num2str(numRun), '/'], paramdir);
if ~exist(workspace_savedir, 'dir')
    mkdir(workspace_savedir);
end

options.workspace_savedir = workspace_savedir;
options.workspace_filenameprefix = [workspace_savedir, 's'];

%=== If complete workspace already exists, return that (don't overwrite files)
workspace_filename_for_complete_run = '';
workspace_filename = [options.workspace_filenameprefix, '_end_of_SMBO', '.mat'];
if options.reuseRun && exist(workspace_filename, 'file')
    workspace_filename_for_complete_run = workspace_filename;
    fprintf(['\n\nRE-USING PREVIOUS RUN!\nReturning complete workspace from file ', workspace_filename_for_complete_run, '\n\n']);
    return
end

global log_fid
log_fid = fopen(logfilename,'w');
global traj_fid
traj_fid = fopen(trajfilename,'w');
global detailed_traj_fid
detailed_traj_fid = fopen(detailed_trajfilename,'w');
global outputToScreen
outputToScreen = options.writeToScreen;
global runTimeForRunningAlgo
runTimeForRunningAlgo = 0;
global resfid;
resfid = fopen(resfilename,'w');
assert(resfid > -1);
assert(log_fid > -1);
assert(traj_fid > -1);
assert(detailed_traj_fid > -1);

bout(strcat('logfile: ', parsePath(logfilename, pwd), '\n'));
bout(strcat('run folder: ', parsePath(workspace_savedir, pwd), '\n'));
function [min_x, min_val, bestconflist, model, incumbent_theta_idx, func, options, rundata] = smbo(func, options, logHeader)
% Function   : SMAC Version 1.1
% Written by : Frank Hutter (hutter@cs.ubc.ca)
% Created on : 11/05/2011
% Last Update: 08/06/2011
% Purpose    : Sequential model-based optimization of expensive mixed
% continuous/discrete blackbox functions
%
% This code comes with no guarantee or warranty of any kind.
%
% For details on SMAC, see our LION-2011 paper.
%
% Input parameters:
%   func: a struct describing the function to be optimized, with the
%         following fields. 
%         Assertions: - At least one of func.cont or func.cat is set and non-empty
%                     - func.cat and func.cont are disjoint (if set)
%                     - union(func.cat, func.cont) = {1:max(max(func.cont),max(func.cat))}
%                     - If func.cont is set, then func.lower_bounds and
%                       func.upper_bounds are set and have the same 
%                       dimensionality as func.cont
%                     - If func.cat is set, then fun.cat_domain_sizes is 
%                       set and has the same dimensionality
%       func.funcHandle: function handle for the blackbox function. Takes 4
%                        arguments: funcHandle(theta, instance_numbers, seeds, censorLimits)
%                        that funcHandle does not actually have to use all
%                        those arguments, see smbo_wrap_simple.m for an
%                        example.
%       
%       func.cont []: N by 1 vector of indices of numerical inputs
%       func.cat []: C by 1 vector of indices of categorical inputs
%
%       func.param_bounds: N+C by 2 vector of lower and upper bounds for numerical inputs
%                           only func.param_bounds(func.cont,:) will be used
%       func.all_values: N+C by 1 vector of domains for categorical inputs
%                           only func.all_values(func.cat) will be used
%                           calls of func.funcHandle will use *indices*
%                           into the domain of each categorical variables,
%                           e.g. one of {1,2,3} for a domain {'a','b','c'} 
%   
%       func.default_values: mandatory input with starting vector
%
%       func.cutoff [inf]:     if not inf, this means the function will accept
%                              a cutoff as input: funcHandle(x, 'cutoff',
%                              cutoff)
%                              in that case, func.cutoff is the maximal
%                              cutoff
%
%       func.features []:    P by d vector of characteristics (features) of 
%                            problem instances ("environmental conditions") 
%                            that we want to optimize a statistic over. 
%                            This is empty if we're just optimizing one 
%                            function (even if it's noisy).
%                            If this is not empty, the function will accept
%                            an additional integer specifying the instance
%                            to use: funcHandle(x, 'instanceIndex',
%                            instanceIndex).
%
%       All additional inputs to funcHandle can be mixed and matched freely.
%
%       func.env []: structure required if func wraps an algorithm run
%
%
%   options: an optional structure containing optional settings
%     Optional fields of options, with default value in square brackets
%       options.seed [1]: seed for a random number generator to ensure repeatability
%       options.maxFunEvals [100*(length(func.cat)+length(func.cont))]
%       options.maxTimeBudget [inf]
%   
% Output parameters: 
%   min_x: 
%     Best found N+C by 1 vector min_x for minimizing funcHandle, where
%          min_x(numerical(n)) in [input_domains.lower_bounds(n),input_domains.upper_bounds(n)]
%          and
%          min_x(categorical(c)) in {1,...,input_domains.cat_domain_sizes(c)}.
%   min_val: value of funcHandle(min_x). Estimation for noisy functions or
%   when dealing with uncontrollable settings to get a statistic over
%   model: for reference, the final model learned

%TODOs: active determination of runlength?
%      error message when combining solqual with mean10
%      capping for solqual: just don't do runs when mean already above lb; should fall out of the code...
% use cached data for validation, even when not using the DB.
if nargin < 1
    fprintf('Usage: smbo(func [, options])\n')
    return
end
if nargin < 2
    options = [];
end
if nargin < 3
    logHeader = '';
end

if ~isfield(options, 'seed')
    options.seed = 1;
end
numRun = options.seed;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: INITIALIZE RANDOM NUMBER GENERATOR
% Use fixed seed for each run for reproducibility (e.g., there is
% randomness in the local search for optimizing expected improvement).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rand('twister',numRun+1);
randn('state',numRun+1);
s = rand('twister');

func = processFunc(func);
rand('twister', s);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: GET AC PARAMETERS FROM DEFAULT FILE AND COMMAND LINE CALL.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options.overallobj = func.overallobj;
options.kappa_max = func.cutoff;
options = set_options(options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: INITIALIZE GLOBALS, OUTPUT FILES AND OUTPUT GENERAL HEADER.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initializeGlobalHouseKeepingVariables();
global writeToScreen;
writeToScreen = options.writeToScreen;
global ThetaUniqSoFar;
[workspace_savedir, paramdir, options, workspace_filename_for_complete_run] = defineOutputFiles(options, func, numRun);
global incumbent_matrix; %#ok<NUSED> % declared here, such that it is saved by save
global allParamStrings; %#ok<NUSED> % declared here, such that it is saved by save

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if a complete run already exists; if so, return that.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(workspace_filename_for_complete_run)
    load(workspace_filename_for_complete_run)
    return
end


if ~isdeployed
    profile off;
    switch options.profile
        case 0
        case 1
            profile on -memory -timer cpu;
        case 2
            profile on -memory -timer real;
        otherwise
            error('unknown profiler type. Options are 0 (off), 1 (cpu), 2(real).');
    end
end

bout(['\n********************************************\nSMBO started at ', datestr(now), '\n********************************************\n'], true);

output_general_header(logHeader, options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: GET OFFLINE VALIDATION DATA FOR THE MODEL.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valdata = getValdata(func, options, numRun);
rand('twister', s);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: INITIALIZE VARIABLES TO KEEP INTERNAL STATISTICS.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
learnTime1 = [];
iterationTime = [];
ls_time = [];
alTunerTime = 0;
iteration = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP: INITIALIZE INSTANCE FEATURES.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_features_for_training_instances = func.features;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START WITH INITIAL DATA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tout(sprintf('Run %d\n', numRun));
outputNewBest(0, 10000000000000, 0, 1, 0, 0, alphabeticalParameterString(func, func.default_values), 0, 0, 0); % 1:default
[incumbent_theta_idx, bestconflist, rundata, ThetaUniqSoFar] = getInitialData(func, options, numRun);

if ~isempty(rundata.iterations)
    iteration = rundata.iterations(end);
end
if ~isempty(rundata.time_until_here)
    alTunerTime = max(rundata.time_until_here);
end

rand('twister', s); % such that any prior randomness does not change the seed
if strcmp(options.method, 'pure-random')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pure random search without a model.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    iteration=0;
    model = 'nomodel';
    minRawAlgoTime = 0.001;

    while ~have_to_stop(alTunerTime, rundata.runTime, func, rundata.used_instance_idxs, options, iteration)
        iteration = iteration+1;

        %=== Sample new config and compare it against incumbent.
        challenger = selectRandomConfigs(func, 1);
        [incumbent_theta_idx, bestconflist, rundata] = compareChallengersAgainstIncumbent(challenger, incumbent_theta_idx, model, func, rundata, iteration, minRawAlgoTime, options, alTunerTime, alTunerTime, bestconflist);
        valdata = outputCurrentStatisticsAndRunFiles(workspace_savedir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options);
    end
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Iterate active learning steps.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while 1
        %=== Set up some housekeeping variables.
        iteration = iteration+1;
        valdata.iteration = iteration;
        iterationTime(iteration) = 0;
        figure_prefix = strcat(paramdir, 'run', num2str(numRun), '/it', num2str(iteration), '-');
        valdata.figure_prefix = figure_prefix;
        
        if strcmp(options.method, 'pure-random')
            model = 'nomodel';
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % LEARN THE MODEL.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            cens_model = rundata.cens;
            y_model = rundata.y;
            total_java_memory = java.lang.Runtime.getRuntime.totalMemory;
            bout(['Max Java memory: ', num2str(java.lang.Runtime.getRuntime.maxMemory), '\n']);
            bout(['Total Java memory: ', num2str(total_java_memory), '\n']);
            bout(['Free Java memory: ', num2str(java.lang.Runtime.getRuntime.freeMemory), '\n']);
            

			%=== Make sure that runtime data is positive and solution quality not too extreme.
            if options.logModel == 1 || options.logModel == 3
                %=== Zeros would break a log model. Replace them by half the
                %=== minimal positive value we have observed (but at most 0.005)
                assert(all(y_model>-1e-6), strcat(['When using a log model, all y values have to be positive, but the actual min y value is ', min(y_model)]));
                if sum(y_model<=0) > 0
                    if sum(y_model>0) > 0
                        min_value = min(0.005, min(y_model(y_model>0))/2);
                    else
                        min_value = 0.005;
                    end
                    y_model(y_model<=0) = repmat(min_value, 1, sum(y_model<=0));
                end
            end
            if any(y_model>1e9)
                warning('Extreme response values (>10^9). That might break the numerical precision of SMAC.');
            end

            switch options.adaptive_capping
                case {0,-1}
                    %=== For now, using 10*cutoff, and learning model without censoring.
                    y_model(find(rundata.cens)) = options.cutoff_penalty_factor .* max(y_model(find(rundata.cens)),func.cutoff); % max is for special case of SAPS-QWH, normally just func.cutoff
					%=== TODO: use the one below instead? (need stat. experiments)
					% y_model(find(rundata.cens)) = options.cutoff_penalty_factor .* func.cutoff;
                    cens_model = zeros(length(rundata.cens),1);
                case -2
                    cens_model = zeros(length(rundata.cens),1);
                case 1
                otherwise
                    error 'capping only has allowed values -2 (count a cap at kappa_i as kappa_i), -1 (count all caps as 10*kappa_max), 0 (always kappa_i=kappa_max; count as 10*kappa_max), and 1 (capped model).'
            end

            used_idxs = [rundata.used_theta_idxs, rundata.used_instance_idxs];
            if options.frac_for_refit ~= 0 && exist('model', 'var') && ~isfield(model, 'constant') && rundata.numNewRunsSinceLastBuild/length(model.y) < options.frac_for_refit
                tic;
                model = updateModel(model, used_idxs(rundata.updatedRunIdxs,:), ThetaUniqSoFar, y_model(rundata.updatedRunIdxs), cens_model(rundata.updatedRunIdxs), 0);
                learnTime1(iteration) = toc;
                bout(['Iteration ', num2str(iteration), ': updating ', options.modelType, ' model using ', num2str(length(rundata.updatedRunIdxs)), ' data points (model had ', num2str(length(rundata.used_theta_idxs)-length(rundata.updatedRunIdxs)), ' data points)... took ', num2str(learnTime1(iteration)), 's.\n']);
                
                rundata.updatedRunIdxs = [];
            else
                clear model;
                tic;
                model = learnModel(used_idxs, ThetaUniqSoFar, all_features_for_training_instances, y_model, cens_model, func.cat, func.all_values, [], cell(1, size(all_features_for_training_instances, 2)), func.cond_params_idxs, func.parent_param_idxs, func.ok_parent_value_idxs, 0, options, func.param_names);
                learnTime1(iteration) = toc;
                bout(['Iteration ', num2str(iteration), ': learning ', options.modelType, ' model using ', num2str(length(rundata.used_theta_idxs)), ' data points (', num2str(rundata.numNewRunsSinceLastBuild), ' new)... took ', num2str(learnTime1(iteration)), 's.\n']);
                
                rundata.updatedRunIdxs = [];
                rundata.numNewRunsSinceLastBuild = 0;
            end
           
            if (options.timeout_incl_learning)
                alTunerTime = alTunerTime + learnTime1(iteration);
            end
            iterationTime(iteration) = iterationTime(iteration) + learnTime1(iteration);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % VALIDATE MODEL ONLY BASED ON ONLINE DATA.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if options.online_crossval && options.schmeeHahn ~= -1
                bout(sprintf(['Prefix for performance plots: ' figure_prefix, '\n']));
                [rmse, cc, ll, cc_rank] = crossValidationPlots(model, 1, 10, figure_prefix);
                bout(sprintf('Cross validation k=10: RMSE=%f, CC=%f, LL=%f, CCrank=%f\n', [rmse, cc, ll, cc_rank]));
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % OFFLINE MODEL VALIDATION PLOTS.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            valStats = [];
            if options.valid || options.just_valid
                [valdata.valObjMu, valdata.valObjVar, valStats] = plotsForValidatingModel(options, model, valdata.dev_theta_idxs, func.name, valdata.valActualObjTest, options.saving, iteration, valdata.next_iteration_to_output, numRun, options.numRunsToSaveDetails, figure_prefix, all_features_for_training_instances, func.overallobj, func, valdata.valTrueMatrixNoTrafo);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % SELECT A SET OF CHALLENGERS.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        switch options.method
            case 'pure-random'
                numChallengers = 1000;
                challengers = spread_hybrid_lhsamp(ceil(rand*1000000), func.dim, numChallengers, func.cat, func.cont, func.num_values, func.param_bounds, 'random', 1);

            case 'al'
                [means, vars] = applyMarginalModel(model, ThetaUniqSoFar, [], 0, 0);
                [challengers, eiTime, valStats] = select_all_challengers(func, model, means, vars, options, incumbent_theta_idx, valdata, valStats, rundata, learnTime1);
%                csvwrite(strcat([workspace_savedir, 'it', num2str(iteration), '-challengers.csv']), challengers);

                ls_time(iteration) = eiTime;
                if (options.timeout_incl_learning)
                    alTunerTime = alTunerTime + ls_time(iteration);
                end
                iterationTime(iteration) = iterationTime(iteration) + ls_time(iteration);
        end
        if options.just_valid
            return;
        end
        %=== Any validation has been done, now really stop.
        if have_to_stop(alTunerTime, rundata.runTime, func, rundata.used_instance_idxs, options, iteration)
            break
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % EVALUATE EACH OF THE CHALLENGERS AGAINST THE INCUMBENT,
        % for a total time at least comparable to the overhead.
        % raw/(learning+raw) > x    <=>     raw > (learning * ax)/(1-x)
        % ceil in order to get the same trajectory most of the time.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        minRawAlgoTime = (ceil(iterationTime(iteration)) * options.frac_rawruntime) / (1-options.frac_rawruntime);
        bout(sprintf('Performing runs for at least %f seconds (fraction options.frac_rawruntime=%f of time in this iteration)\n', [minRawAlgoTime, options.frac_rawruntime]));
        [incumbent_theta_idx, bestconflist, rundata] = compareChallengersAgainstIncumbent(challengers, incumbent_theta_idx, model, func, rundata, iteration, minRawAlgoTime, options, alTunerTime, iterationTime(iteration), bestconflist);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % OUTPUT CURRENT STATISTICS AND RUNS FILES.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        valdata = outputCurrentStatisticsAndRunFiles(workspace_savedir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options);
    end
end

valdata.next_iteration_to_output = iteration;
outputCurrentStatisticsAndRunFiles(workspace_savedir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options);

%== Get empirical mean and variance of the mean to output.
data = rundata.y(rundata.used_theta_idxs==incumbent_theta_idx)';
min_val = combineRunObjectives(options.overallobj, data, func.cutoff);
min_x = config_back_transform(ThetaUniqSoFar(incumbent_theta_idx,:), func);

bout(['\n********************************************\nSMBO finished at ', datestr(now), '. Final best objective: ', num2str(min_val), '\nBest configuration:\n'], true);
paramString = alphabeticalParameterString(func, min_x, true);
bout([paramString, '\n********************************************\n'], true);

workspace_filename = [options.workspace_filenameprefix, '_end_of_SMBO', '.mat'];
bout(sprintf(['Saving workspace at end of SMBO run to ' workspace_filename '\n']));
save(workspace_filename);
function [options, opt_args_idxs] = parse_smbo_arguments(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARSE COMMAND LINE PARAMETERS.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options = struct;
opt_args_idxs = ones(length(varargin)/2, 1);
for i=1:2:length(varargin)
    switch varargin{i}
        %=== SMBO parameters for the model.
        case 'model'
            options.modelType = varargin{i+1};
        case 'subModel'
            options.subModelType = varargin{i+1};
        case 'logModel'
            options.logModel = varargin{i+1};
            if isdeployed, options.logModel = str2num(options.logModel); end
        case 'remove_constant_Theta'
            options.remove_constant_Theta = varargin{i+1};
            if isdeployed, options.remove_constant_Theta = str2num(options.remove_constant_Theta); end
        case 'ignore_conditionals'
            options.ignore_conditionals = varargin{i+1};
            if isdeployed, options.ignore_conditionals = str2num(options.ignore_conditionals); end
        case 'pca'
            options.pca = varargin{i+1};
            if isdeployed, options.pca = str2num(options.pca); end
        case 'cap_slack'
            options.cap_slack = varargin{i+1};
            if isdeployed, options.cap_slack = str2num(options.cap_slack); end
        case 'min_variance'
            options.min_variance = varargin{i+1};
            if ischar(options.min_variance), options.min_variance = str2num(options.min_variance); end
            
        %== SMBO parameters for RF model in particular.
        case 'split_ratio'
            options.split_ratio_init = varargin{i+1};
            if isdeployed, options.split_ratio_init = str2num(options.split_ratio_init); end
        case 'Splitmin'
            options.Splitmin_init = varargin{i+1};
            if isdeployed, options.Splitmin_init = str2num(options.Splitmin_init); end
        case 'orig_rf'
            options.orig_rf = varargin{i+1};
            if isdeployed, options.orig_rf = str2num(options.orig_rf); end
        case 'nSub'
            options.nSub = varargin{i+1};
            if isdeployed, options.nSub = str2num(options.nSub); end
        case 'frac_for_refit'
            options.frac_for_refit = varargin{i+1};
            if isdeployed, options.frac_for_refit = str2num(options.frac_for_refit); end
        case 'storeDataInLeaves'
            options.storeDataInLeaves = varargin{i+1};
            if isdeployed, options.storeDataInLeaves = str2num(options.storeDataInLeaves); end
        %== SMBO parameters for PP model in particular.
        case 'trainSubSize'
            options.trainSubSize = varargin{i+1};
            if isdeployed, options.trainSubSize = str2num(options.trainSubSize); end
            
        %=== SMBO parameters for the selection of new settings.
        case 'method'
            options.method = varargin{i+1};
        case 'frac_rawruntime'
            options.frac_rawruntime = varargin{i+1};
            if isdeployed, options.frac_rawruntime = str2num(options.frac_rawruntime); end
        case 'timeout_incl_learning'
            options.timeout_incl_learning = varargin{i+1};
            if isdeployed, options.timeout_incl_learning = str2num(options.timeout_incl_learning); end
        case 'reproducibilityMode'
            options.frac_rawruntime = varargin{i+1};
            options.timeout_incl_learning = varargin{i+1};
            if isdeployed
                options.frac_rawruntime = str2num(options.frac_rawruntime);
                options.timeout_incl_learning = str2num(options.timeout_incl_learning);
            end
            options.frac_rawruntime = 1-options.frac_rawruntime;
            options.timeout_incl_learning = 1-options.timeout_incl_learning;
            
        %=== In particular, SMBO parameters for optimizing EIC.
        case 'numLS'
            options.numLSbest = varargin{i+1};
            if isdeployed, options.numLSbest = str2num(options.numLSbest); end
        case 'numRandomInEiOpt'
            options.numRandomInEiOpt = varargin{i+1};
            if isdeployed, options.numRandomInEiOpt = str2num(options.numRandomInEiOpt); end
        case 'ei_inc'
            options.ei_inc = varargin{i+1};
            if isdeployed, options.ei_inc = str2num(options.ei_inc); end
        case 'ei_crit'
            options.expImpCriterion = varargin{i+1};
            if isdeployed, options.expImpCriterion = str2num(options.expImpCriterion); end

        %=== SMBO parameters for intensification strategy.
        case 'intens'
            options.intens_schedule = varargin{i+1};
            if isdeployed, options.intens_schedule = str2num(options.intens_schedule); end

        %=== SMBO parameter for capping strategy.
        case 'capping'
            options.adaptive_capping = varargin{i+1};
            if isdeployed, options.adaptive_capping = str2num(options.adaptive_capping); end
            
        %=== SMBO parameters for starting from an existing data file.
        case 'initialDataFilePrefix'
            options.initialDataFilePrefix = varargin{i+1};
        case 'onlyOneChallenger'
            options.onlyOneChallenger = varargin{i+1};
            if isdeployed, options.onlyOneChallenger = str2num(options.onlyOneChallenger); end
   
        %=== SMBO parameters for alternate termination criteria.
        %=== These should not affect the trajectory.
        case 'numiter'
            options.numIterations = varargin{i+1};
            if isdeployed, options.numIterations = str2num(options.numIterations); end
        case 'numruns'
            options.totalNumRunLimit = varargin{i+1};
            if isdeployed, options.totalNumRunLimit = str2num(options.totalNumRunLimit); end
        case 'runtimeLimit'
            options.runtimeLimit = varargin{i+1};
            if isdeployed, options.runtimeLimit = str2num(options.runtimeLimit); end
        case 'maxn' 
            options.maxn = varargin{i+1};
            if isdeployed, options.maxn = str2num(options.maxn); end
        case 'nInit' 
            options.nInit = varargin{i+1};
            if isdeployed, options.nInit = str2num(options.nInit); end

        %=== Parameters for what to keep track of in the experiment. 
        %=== These should not affect the trajectory.
        case 'online_cv'
            options.online_crossval = varargin{i+1};
            if isdeployed, options.online_crossval = str2num(options.online_crossval); end
        case 'evalAllIncumbents'
            options.evalAllIncumbents = varargin{i+1};
            if isdeployed, options.evalAllIncumbents = str2num(options.evalAllIncumbents); end
        case 'evalTimesIncumbents'
            options.evalTimesIncumbents = varargin{i+1};
            if isdeployed, options.evalTimesIncumbents = str2num(options.evalTimesIncumbents); end            
            
        case 'experiment_name'
            options.experiment_name = varargin{i+1};
        case 'writeToScreen'
            options.writeToScreen = varargin{i+1};
            if isdeployed, options.writeToScreen = str2num(options.writeToScreen); end            
        case 'offline_validation'
            options.offline_validation = varargin{i+1};
            if isdeployed, options.offline_validation = str2num(options.offline_validation); end
        case 'outputFolderSuffix'
            options.outputFolderSuffix = varargin{i+1};
        case 'profile'
            options.profile = varargin{i+1};
            if isdeployed, options.profile = str2num(options.profile); end
        case 'final_outdir'
            options.final_outdir = varargin{i+1};
        case 'reuseRun'
            options.reuseRun = varargin{i+1};

        case {'valid', 'just_valid', 'matrix_valid', 'ehFeature'}
            % no-op, old unused inputs
        otherwise
            opt_args_idxs((i+1)/2) = 0;
    end
end

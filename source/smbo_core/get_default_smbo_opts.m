function options = get_default_smbo_opts()
options = [];   

options.profile = 0;
options.reuseRun = 0;

options.adaptive_capping = 0;
options.cap_slack = 2;

% Parameters for the log gridding.
options.maxn = 2000;

%=== Basic parameters of model-based optimization.
options.initType = 'random_lhd'; %'random_lhd'; %'random'; %'ihs' 'spo'; 'inc_lhd'
options.nInit = -1;%100;

options.modelType =  'rf';               % model     Choices: 'rf', 'javarf', 'fastrf', 'GPML'
options.overallobj = 'mean';
options.intens_schedule = 7;             % intens    Choices: 3/4 SPO+, 7: SMAC. gone: 0 (spo0.3), 1 (spo0.4), 2 (williams)
options.ei_inc = 2;                      % ei_inc    Choices: 0 (inc), 1 (samp_min), 2 (spo), 3 (inc_ucb)
options.expImpCriterion = 0;             % ei_crit   Choices: 0 (eEI), 1 (EI2), 2 (cEI), 3 (EI), 4 (EIh)

options.frac_rawruntime = 0.5; % min. 50% of total time is raw runtime of target algorithm
options.timeout_incl_learning = 1;
options.method = 'al';

options.min_variance = 1e-14;
options.remove_constant_Theta = 1;
options.ignore_conditionals = 0;

%=== PARAMETERS for GAUSSIAN PROCESS MODELLING
options.subModelType =  'GP-hybridiso';
options.strategyForMissing = 0; %-1: mean +/- unc, where unc = MAX(max-mean, mean-min); 0: subtree average; 1: 50-50 random; 4: optimistic
options.logModel = 1;                    % 0: split untransformed, store untransformed, tree means/vars on untransformed. Return untransformed.
                                         % 1: split transformed, store untransformed, tree mean on untransformed then transform. tree var is 0. Return transformed. 
                                         % 2: split transformed, store untransformed, tree mean/var on untransformed. Return untransformed.
                                         % 3: split transformed, store transformed, tree mean/var on transformed. Return transformed.
                                         % If logModel is 1 or 3, model.y stores the transformed data.
options.numIterations = 100000;
options.totalNumRunLimit = 100000;
options.runtimeLimit = inf;

%=== PARAMETERS for RANDOM FOREST MODELLING
options.opt = 0;

options.nSub = 10; 
options.kappa_max = inf;
options.frac_for_refit = 0; % refit a new tree on each data point
options.storeDataInLeaves = 0;

options.orig_rf = 1;

options.pca = 7; % for SMAC paper
options.splitMinMax = 10;

options.Splitmin_init = 10;
options.split_ratio_init = 5.0/6;
options.Splitmincens_init = 5;
% options.Splitmin_init = 3; % will be normalized to [0,1], then * splitMinMax, so will be 10
% options.split_ratio_init = 2; % * (options.paramsUpperBound-options.paramsLowerBound) + options.paramsLowerBound, so will be 5.0/6
% options.Splitmincens_init = 0;

options.paramsLowerBound = -3;
options.paramsUpperBound = 3;

%=== PARAMETERS for KERNEL HYPERPARAMETER OTPIMIZATION
options.hyp_opt_obj = 'mll';%'marg-rmse'; %'marg', 'marg-cc', %'mll'; %'cv-ll';%'mll'; %mll does not work for censoring.
options.hyp_opt_algorithm = 'minFunc'; %; Options: %'minFunc';%'cma-es'; 'direct'; 'minimize'. TODO: use direct for low dimensions
options.crossVal_ll_k = 2; % Number of folds for cross-validation (conditional parameter, active iff hyp_opt_obj= 'cv-ll')
options.hyp_opt_numTries = 1; % conditional parameter for local optimizers.

options.trainSubSize = 300;
options.ppSize = 300;

options.schmeeHahn = -2;

%=== PARAMETERS for FUNCTION TRANSFORMATION and ACTIVE LEARNING
options.N_s = 100;
options.numLSbest = 10;
options.numRandomInEiOpt = 10000;
options.onlyOneChallenger = 0;

%=== PARAMETERS for OPTIMIZATION of EXPECTED IMPROVEMENT
options.hyp_opt_steps = 50;

options.evalAllIncumbents = 0;
options.evalTimesIncumbents = 0;
options.just_valid = 0;
options.valid = 0;
options.online_crossval = 0;
options.matrix_validation = 0;

options.writeToScreen = 1;
options.experiment_name = '';
options.numRunsToSaveDetails = 2;
options.saving = 1;
options.workspace_savedir = '.';
function [func, func_args_idxs] = parse_scenario_arguments(func, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARSE COMMAND LINE PARAMETERS PERTAINING THE CONFIGURATION SCENARIO.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
func_args_idxs = ones(length(varargin)/2, 1);
func.validN = 1000; % default value
for i=1:2:length(varargin)
    switch varargin{i}
        %=== Command line inputs
        case 'config_file'
            func.config_file = varargin{i+1};
        case 'scenario_file'
            func.scenario_file = varargin{i+1};

        %=== params in config file
        case 'scenario_path'
            func.scenario_path = varargin{i+1};
        case 'rootdir'
            func.rootdir = varargin{i+1};
        case 'outdir'
            func.outdir = varargin{i+1};
        case 'tmpdir'
            func.env.tmpdir = varargin{i+1};
            
        %=== Parameters of the scenario file.
        case {'params_filename', 'paramfile'}
            func.env.params_filename = varargin{i+1};
        case {'exec_path', 'execdir'}
            func.env.exec_path = varargin{i+1};
        case {'executable', 'algo'}
            func.env.executable = varargin{i+1};
        case {'matlabfun'}
            func.env.matlabfun = varargin{i+1};
        case 'tunerTimeout'
            func.tuningTime = str2num(varargin{i+1});
        case {'cutoff', 'cutoff_time'}
            func.cutoff = str2num(varargin{i+1});
        case {'overallobj', 'overall_obj'}
            func.overallobj = varargin{i+1};
        case {'singleRunObj', 'run_obj'}
            func.singleRunObjective = varargin{i+1};
        case 'instance_file'
            func.local_instance_file = varargin{i+1};
        case {'feature_file', 'train_instance_file_with_features'}
            func.feature_file = varargin{i+1};
            func.features_defined = 1;
        case 'instance_seed_file_prefix'
            func.local_instance_seed_file_prefix = varargin{i+1};
        case 'test_instance_seed_file'
            func.local_test_instance_seed_file = varargin{i+1};
        case 'test_instance_file'
            func.local_test_instance_file = varargin{i+1};
        case 'deterministic'
            func.deterministic = varargin{i+1};
            if isdeployed, func.deterministic = str2num(func.deterministic); end
        case 'func_name'
            func.name = varargin{i+1};
        case 'validN'
            func.validN = varargin{i+1};
            if isdeployed, func.validN = str2num(func.validN); end

        case 'force_runtime_cap_at_limit'
            func.force_runtime_cap_at_limit = varargin{i+1};
            if isdeployed, func.force_runtime_cap_at_limit = str2num(func.force_runtime_cap_at_limit); end

        case 'relativePaths'
            func.relativePaths = varargin{i+1};
            if isdeployed, func.relativePaths = str2num(func.relativePaths); end
        case {'objective', 'cheap', 'numTrainingInstances', 'numTestInstances', 'matlab_fun', 'db', 'runlength'}
            warning(['The option ', varargin{i}, ' has been deprecated and will be ignored.']);
            % no-op, old unused inputs
        otherwise
            if nargout == 2
                func_args_idxs((i+1)/2) = 0;
            elseif nargout == 1
                error(['Unknown option ', varargin{i}]);
            end
    end
end
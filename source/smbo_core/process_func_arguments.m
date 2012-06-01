function [func, func_args_idxs] = process_func_arguments(varargin)
%% Read arguments to create func and options.
func.features_defined = 0;
[func, func_args_idxs] = parse_scenario_arguments(func, varargin{:});

%% Read config file for paths.
func.scenario_path = '.';
func.rootdir = '.';
func.outdir = 'out/';
if isfield(func, 'config_file')
    if ~exist(func.config_file, 'file')
        error(['Config file ', func.config_file, ' does not exist.']);
    end
elseif exist('smbo_config.txt', 'file')
    func.config_file = 'smbo_config.txt';
end
if isfield(func, 'config_file')
    lines=textread(func.config_file, '%s', 'delimiter', '\n');
    for i=1:length(lines)
        line = lines{i};
        matches = regexp(line, '([^=#]*)=([^#]*)(#.*)?', 'tokens', 'once');
        if length(matches) < 2
            if ~isempty(line) && isempty(regexp(line, '^\s*(#.*)?\s*$', 'once'))
                error(['Line ', line, ' in config file does not match syntax <param>=<value>[#<comments>]']);
            else
                continue
            end
        end
        name = ddewhite(matches{1});
        value = ddewhite(matches{2});

        try
            func = parse_scenario_arguments(func, name, value);
        catch ME
            fprintf(['Error parsing config file ', filename, '\n']);
            ME.rethrow();
        end
    end
end

% Overwrite any settings from config file if set in command line call.
[func, func_args_idxs] = parse_scenario_arguments(func, varargin{:});

%% Read settings from scenario file.
if isfield(func, 'scenario_file')
    filename = parsePath(func.scenario_file, parsePath(func.scenario_path, func.rootdir));
    if ~exist(filename, 'file')
        origfilename = filename;
        filename = strcat(filename, '.txt');
        if ~exist(filename, 'file')
            error(['Scenario file ', origfilename, ' does not exist.']);
        end
    end
    lines=textread(filename, '%s', 'delimiter', '\n');
    for i=1:length(lines)
        line = lines{i};
        matches = regexp(line, '([^=#]*)=([^#]*)(#.*)?', 'tokens', 'once');
        if length(matches) < 2
            if ~isempty(line) && isempty(regexp(line, '^\s*(#.*)?\s*$', 'once'))
                error(['Line ', line, ' in scenario file does not match syntax <param>=<value>[#<comments>]']);
            else
                continue
            end
        end
        name = ddewhite(matches{1});
        value = ddewhite(matches{2});
        
        try
            func = parse_scenario_arguments(func, name, value);
        catch ME
            fprintf(['Error parsing scenario file ', filename, '\n']);
            ME.rethrow();
        end
    end
    [a, func.name] = fileparts(func.scenario_file);
end

% Overwrite any settings from scenario file if set in command line call.
[func, func_args_idxs] = parse_scenario_arguments(func, varargin{:});
if ~func.features_defined
    warning('No feature file specified. It is possible to use SMAC without features, but (at least some simple) features typically improve performance. To use features, make a file listing one training instance per line, followed by the features for that instance. Then specify that file instead of the instance_file (replace "instance_file" with "feature_file" or "train_instance_file_with_features").');
end

%% Make sure all required settings are specified.
mandatory_inputs = {'tuningTime', 'cutoff', 'overallobj', 'name'};
for input = mandatory_inputs
    assert(isfield(func, input), ['func.', char(input), ' is a mandatory input and must either be specified in the scenario file or in the command line call.']); 
end

func.outdir_rel = func.outdir;
func.outdir = parsePath(func.outdir, func.rootdir);

if ~isfield(func, 'env')
    error('Must specify either external algorithms (exec_path & executable) or internal function (matlabfun)');
end
if isfield(func.env, 'exec_path') || isfield(func.env, 'executable')
    assert(isfield(func.env, 'exec_path'), 'exec_path must be set for optimizing Matlab-external algorithms');
    assert(isfield(func.env, 'executable'), 'executable must be set for optimizing Matlab-external algorithms');
    assert(isfield(func.env, 'params_filename'), 'params_filename must be set for optimizing Matlab-external algorithms');
    func.external = 1;     
else
    assert(isfield(func.env, 'matlabfun'), 'matlabfun must be set for internal Matlab-internal functions.');
    func.external = 0;
end

if isfield(func.env, 'params_filename')
    %=== Parse the configuration space from the params file.
    params_filename = parsePath(func.env.params_filename, func.rootdir);
    [func.cat, func.cont, func.param_names, func.all_values, func.param_bounds, func.param_trafo, func.is_integer_param, func.default_values, func.cond_params_idxs, func.parent_param_idxs, func.ok_parent_value_idxs] = read_params(params_filename);
end
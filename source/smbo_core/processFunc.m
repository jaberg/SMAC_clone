function func = processFunc(func)
    %%%% Process the func structure to create additional fields needed.
    if isfield(func, 'processed') && func.processed
        return;
    end
    
    defaults = {                                        ...
                'features', 0,                          ...
                'deterministic', 0,                     ...
                'cutoff', inf,                          ...
                'tuningTime', inf,                      ...
                'overallobj', 'mean',                   ...
                'singleRunObjective', 'runtime',        ...
                'outdir', './out',                      ...
                'cat', [],                              ...
                'cont', [],                             ...
                'force_runtime_cap_at_limit', 0         ...
    };
           
    for i=1:2:length(defaults)
        if ~isfield(func, defaults{i})
            func.(defaults{i}) = defaults{i+1};
        end
    end
    
    if ~isfield(func, 'numTrainingInstances')
        func.numTrainingInstances = size(func.features,1);
    end

    func.dim = length(func.cat)+length(func.cont);
    assert(func.dim > 0, 'At least one of func.cat or func.cont must be set and non-empty');
    assert(func.dim == length(union(func.cat, func.cont)), 'func.cat and func.cont must be disjoint');
    assert(all(1:func.dim == union(func.cont,func.cat)), 'func.cat and func.cont must partition 1:max(union(func.cont,func.cat))');
    
    if ~isfield(func, 'name') && isfield(func, 'inputFuncHandle')
        func.name = func2str(func.inputFuncHandle);
    end
    
    if ~isfield(func, 'param_names')
        func.param_names = {};
        for i=1:func.dim
            func.param_names{i,1} = strcat('param',num2str(i));
        end
    end
    
    if ~isfield(func, 'all_values')
        assert(isempty(func.cat), 'If there are categorical values, their domain has to be specified.');
        func.all_values = cell(func.dim,1);
        for i=1:func.dim
            func.all_values{i} = {};
        end
    end

    if ~isfield(func, 'param_bounds')
        assert(isempty(func.cont), 'If there are numerical values, their bounds have to be specified in field param_bounds.');
        func.param_bounds = -ones(func.dim,2);
    end
    
    if ~isfield(func, 'is_integer_param')
        func.is_integer_param = -ones(func.dim,1);  % so it throws an error if queried.
        func.is_integer_param(func.cont) = 0;
    end

    if ~isfield(func, 'param_trafo')
        func.param_trafo = -ones(func.dim, 1); % so it throws an error if queried.
        func.param_trafo(func.cont) = 0;
    end
    
    if ~isfield(func, 'seeds') 
        if ~func.deterministic
            func.seeds = ceil((2^31-1)*rand(func.numTrainingInstances,ceil(1000000/func.numTrainingInstances)));
        else
            func.seeds = ceil((2^31-1)*rand(func.numTrainingInstances,1));
        end
    end

    %=== Handle bounds: orig_orig_*_bound is what's passed in by the user. 
    %=== orig_param_*_bound is after linearizing, 
    %=== and param_bounds is after normalizing to [0,1], so always [zeros,ones]
    func.orig_param_lower_bound = func.param_bounds(:,1);
    func.orig_param_upper_bound = func.param_bounds(:,2);
    for i=1:length(func.cont)
        c=func.cont(i);
        func.transformed_param_lower_bound(c) = param_transform(func.orig_param_lower_bound(c), func.param_trafo(c));
        func.transformed_param_upper_bound(c) = param_transform(func.orig_param_upper_bound(c), func.param_trafo(c));
    end
    func.param_bounds(:,1) = 0;
    func.param_bounds(:,2) = 1;

    if ~isfield(func, 'default_values')
        func.user_default_values = -ones(func.dim, 1); % so it throws an error if queried.
        func.user_default_values(func.cont) = (func.orig_param_lower_bound(func.cont)+func.orig_param_upper_bound(func.cont))/2;
    else
        func.user_default_values = func.default_values;
    end
    func.default_values = config_transform(func.user_default_values', func)';
    
    if ~isfield(func, 'cond_params_idxs')
        func.cond_params_idxs = [];
        func.parent_param_idxs = [];
        func.ok_parent_value_idxs = [];
    end

    func.num_values = zeros(1,func.dim);
    for i=1:func.dim
        func.num_values(i) = length(func.all_values{i});
    end

    % assert(size(func.cont)==size(func.lower_bounds), 'sizes of func.cont and func.lower_bounds must be equal');
    % assert(size(func.cont)==size(func.upper_bounds), 'sizes of func.cont and func.upper_bounds must be equal');
    % assert(size(func.cat)==size(func.cat_domain_sizes), 'sizes of func.cat and func.cat_domain_sizes must be equal');
    assert(length(func.default_values)==func.dim, strcat('func.default_values must have dimensionality ', num2str(func.dim)));
    assert(length(func.param_names) == func.dim, 'func.param_names must be a cell array of length length(func.cat)+length(func.cont)');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SETTING UP ANONYMOUS FUNCTIONS - HAS TO BE IN THE END since func is passed.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isfield(func, 'external')
        if func.external
            func.funcHandle = @(Theta_idx,instance_numbers,seeds,censorLimits) get_single_results(func, Theta_idx, seeds, func.instance_filenames(instance_numbers), censorLimits);
        else
            if ~isfield(func, 'inputFuncHandle')
                %=== Anonymous function to evaluate the function read in as a string.
                func.inputFuncHandle = @(Theta, instance_numbers, seeds, censorLimits) feval(func.env.matlabfun, Theta, instance_numbers, seeds, censorLimits);
            end
            %=== Build anonymous function dealing with censoring.
            func.funcHandle = @(Theta_idx,instanceNumbers,seeds,censorLimits) censoredReading(func, func.inputFuncHandle, Theta_idx, instanceNumbers, seeds, censorLimits);
        end
    end
    func.processed = true;
end

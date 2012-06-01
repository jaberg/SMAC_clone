function [cat, cont, param_names, all_values, param_bounds, param_trafo, is_integer_param, default_values, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs] = read_params(filename)
% The defaults are indices in the case of categorical variables.

fprintf('Reading params from %s\n', filename);
lines=textread(filename, '%s', 'delimiter', '\n');

cat = [];
cont = [];
param_names = {};
all_values = {};
default_values = [];
param_bounds = [];
is_integer_param = [];
param_trafo = [];
cond_params_idxs = [];
parent_param_idxs = [];
ok_parent_value_idxs = {};

numParam = 0;
%=== Parse parameter names, domains, and default values.
for i=1:length(lines)
    textline = lines{i};
    
    %=== Ignore empty lines and comment lines.
    if isempty(textline) || ~isempty(regexp(textline, '^\s*#'))
        continue;
    end
    %=== Conditionals are treated separately.
    if regexp(textline, 'Conditionals:') 
        break;
    end
    %=== Forbiddens are treated separately.
    if regexp(textline, 'Forbidden:') 
        break;
    end
    numParam = numParam+1;

    %=== Match parameter with categorical choices.
    matches = regexp(textline, '^([^{]+){(.*)}.*\[(.*)\]', 'tokens', 'once');
    if ~isempty(matches)
        cat(end+1) = numParam;
        param_name = ddewhite(matches{1});
        value_string = matches{2};
        values = strsplit(',', value_string);
        for j=1:length(values)
            values{j} = ddewhite(values{j});
        end
        default_value = ddewhite(matches{3});
        
        param_names{numParam,1} = param_name;
        all_values{numParam} = values;
        
        %=== Find index of default value.
        default_idx = -1;
        for k=1:length(values)
            if strcmp(values{k}, default_value)
                default_idx = k;
                break;
            end
        end
        assert(default_idx > -1);
        default_values(numParam,1) = default_idx;
        param_bounds(numParam,:) = [0, 0]; % not active.
        param_trafo(numParam) = -1; % so it throws an error if accessed.
        is_integer_param(numParam) = -1; % so it throws an error if accessed.
        
    else
        %=== Match parameter with continuous domain.
        matches = regexp(textline, '^([^\[]+)\[([^,]+),([^\]]+)\].*\[(.*)\]([^#]*)', 'tokens', 'once');
        if isempty(matches)
            errstr = strcat(['line matching neither categorical nor continuous parameter: ' textline])
            error(errstr);
        end        
        cont(end+1) = numParam;
        param_name = ddewhite(matches{1});
        lower_bound = str2num(ddewhite(matches{2}));
        upper_bound = str2num(ddewhite(matches{3}));
        default_value = str2num(ddewhite(matches{4}));
        special_characteristics = ddewhite(matches{5}); %i: integer, l:logtransform

        if strfind(special_characteristics, 'i')
            is_integer_param(numParam) = 1;
        else
            is_integer_param(numParam) = 0;
        end

        if strfind(special_characteristics, 'l')
            param_trafo(numParam) = 1; % log(x)
        else
            if strfind(special_characteristics, 'L') 
                param_trafo(numParam) = 2; % logarithmic: -log(1-x)
            else
                param_trafo(numParam) = 0; % id
            end
        end
        
        param_names{numParam,1} = param_name;
        param_bounds(numParam,:) = [lower_bound, upper_bound];
        default_values(numParam,1) = default_value;
        all_values{numParam} = []; % not active.
    end
end

%=== Even though we are so far not using conditionals in the model, we do
%=== use them when writing to the database, so we need to know about them.
if regexp(textline, 'Conditionals:') 
    for j=i+1:length(lines)
        textline = lines{j};

        %=== Ignore empty lines and comment lines.
        if isempty(textline) | regexp(textline, '^\s*#')
            continue;
        end
        %=== Forbiddens are treated separately.
        if regexp(textline, 'Forbidden:') 
            break;
        end

        %=== Only allow categorical parents of conditionals for now.
        matches = regexp(textline, '^(.*)\|(.*) in\s*{(.*)}', 'tokens', 'once');
        cond_name = ddewhite(matches{1});
        parent_name = ddewhite(matches{2});
        value_string = matches{3};

        %=== Find index of conditional parameter.
        cond_idx = -1;
        for i=1:length(param_names)
            if strcmp(param_names{i}, cond_name)
                cond_idx = i;
                break
            end
        end
        assert(cond_idx > -1);

        %=== Find index of parent parameter.
        parent_idx = -1;
        for i=1:length(param_names)
            if strcmp(param_names{i}, parent_name)
                parent_idx = i;
                break
            end
        end
        assert(parent_idx > -1);

        %=== Find indices of allowed values -- only allow categorical
        %=== parents of conditionals for now.
        allowed_values = strsplit(',', value_string);
        allowed_idxs = [];
        for k=1:length(allowed_values)
            allowed_values{k} = ddewhite(allowed_values{k});
            allowed_idxs(end+1) = find(strcmp(all_values{parent_idx}, allowed_values{k}));
        end
        
        cond_params_idxs(end+1) = cond_idx;
        parent_param_idxs(end+1) = parent_idx;
        ok_parent_value_idxs{end+1} = allowed_idxs;
    end
end

%=== Forbidden combinations are not supported yet.
if regexp(textline, 'Forbidden:')
    error('We cannot handle forbidden assignments yet.')
end


%=== Sort parameters alphabetically -- use that order for indexing everywhere (e.g. for conditionals).
[tmp, sorted_idxs] = sort(param_names);
param_names = param_names(sorted_idxs);
all_values = all_values(sorted_idxs);
param_trafo = param_trafo(sorted_idxs);
param_bounds = param_bounds(sorted_idxs,:);
default_values = default_values(sorted_idxs);
is_integer_param = is_integer_param(sorted_idxs);

reverse_index(sorted_idxs) = 1:length(sorted_idxs);
cat = reverse_index(cat);
cont = reverse_index(cont);
cond_params_idxs = reverse_index(cond_params_idxs);
parent_param_idxs = reverse_index(parent_param_idxs);

assert(all(~isnan(default_values)));
assert(all(~isinf(param_bounds(:,1))));
assert(all(~isinf(param_bounds(:,2))));
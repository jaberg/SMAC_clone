% Theta_inst_idxs is a N*2 matrix of [theta_idx, inst_idx] pairs indexing into ThetaUniqSoFar and all_instance_features.
function model = learnModel(Theta_inst_idxs, ThetaUniqSoFar, all_instance_features, y, cens, thetaCat, thetaCatDomains, xCat, xCatDomains, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs, isclean, options, names, varargin)
if nargin < 15
    names = {};
end
if ~isempty(xCat)
    error('so far, this code only allows numerical features');
end
if size(Theta_inst_idxs, 2) ~= 2
    error('Badly formatted Theta_inst_idxs.');
end

nvars = size(ThetaUniqSoFar, 2);
nfeatures = size(all_instance_features, 2);
%% === If the inputs have not been cleaned yet (remove constant columns and transform y values), do that
if ~isclean
    Theta = ThetaUniqSoFar(unique(Theta_inst_idxs(:,1)), :);
    if options.remove_constant_Theta    
        constant_Theta_columns = determine_constants(Theta, 1);
    else
        constant_Theta_columns = [];
    end
    
    if ~options.ignore_conditionals
        %=== preprocess conditionals and get rid of definitely inactive parameters.
        conditionals = unique(cond_params_idxs);
        idxs_to_remove = [];
        for i=1:length(conditionals) % for each conditional
            idxs = find(cond_params_idxs==conditionals(i));
            is_all_good = true;
            is_bad = false;
            for j=1:length(idxs) % for each parent, check if all its values are ok values or bad values.
                idx = idxs(j);
                parent_values = unique(Theta(:,parent_param_idxs(idx)));
                ok_values = ok_parent_value_idxs{idx};
                numcommon = length(intersect(parent_values, ok_values));

                if numcommon ~= length(ok_values) % some parent has some bad value, so this variable might not always be enabled.
                    is_all_good = false;
                end
                if numcommon == 0 % all bad values. A single parent with all bad values means this variable cannot be enabled.
                    is_bad = true;
                    break;
                end
            end

            if is_bad % this conditional is never enabled so treat it like a constant.
                constant_Theta_columns = [constant_Theta_columns, conditionals(i)];
            elseif is_all_good
                % this conditional is always enabled so get rid of it as a conditional.
                idxs_to_remove = [idxs_to_remove, idxs];
            end
        end

        % remove conditionals that are always enabled from the list of conditionals.
        cond_idxs_to_keep = setdiff(1:length(cond_params_idxs), idxs_to_remove);
        cond_params_idxs = cond_params_idxs(cond_idxs_to_keep);
        parent_param_idxs = parent_param_idxs(cond_idxs_to_keep);
        ok_parent_value_idxs = ok_parent_value_idxs(cond_idxs_to_keep);
    end
    
    %=== Determine what columns of Theta to keep, and update indices into columns.
    kept_Theta_columns = setdiff(1:nvars, constant_Theta_columns);
    
    % number of columns before i that are constant
    Theta_column_is_constant = zeros(nvars, 1);
    Theta_column_is_constant(constant_Theta_columns) = 1;
    numConstant = zeros(nvars, 1);
    for i=2:size(Theta,2)
        numConstant(i) = numConstant(i-1) + Theta_column_is_constant(i-1);
    end
    
    % update conditional parameters and thetaCat after dropping constant columns of Theta
    %=== E.g. thetaCat = [3,7,8] and params 2&3 are constant. New thetaCat is [5,6]
    is_ok_cond = zeros(length(cond_params_idxs), 1);
    for i=1:length(cond_params_idxs)
        if Theta_column_is_constant(cond_params_idxs(i)) % if the conditional parameter is constant, we skip it.
            continue;
        end
        cond_params_idxs(i) = cond_params_idxs(i) - numConstant(cond_params_idxs(i));
        parent_param_idxs(i) = parent_param_idxs(i) - numConstant(parent_param_idxs(i));
        is_ok_cond(i) = 1;
    end
    is_ok_cond = find(is_ok_cond);
    cond_params_idxs = cond_params_idxs(is_ok_cond);
    parent_param_idxs = parent_param_idxs(is_ok_cond);
    ok_parent_value_idxs = ok_parent_value_idxs(is_ok_cond);
    
    is_cat_theta = zeros(nvars,1);
    is_cat_theta(thetaCat) = 1;
    is_cat_theta = is_cat_theta(kept_Theta_columns);
    thetaCat = find(is_cat_theta);

    thetaCatDomains = thetaCatDomains(kept_Theta_columns);
    ThetaUniqSoFar = ThetaUniqSoFar(:,kept_Theta_columns);
    
    if ~isempty(names)
        assert(length(names) == nvars, 'The specified variable names must match the number of variables there are.');
        names = names(kept_Theta_columns);
    end

    %%    
    % === find constant instance features
    used_instance_idxs = unique(Theta_inst_idxs(:,2));
    constant_X_columns = determine_constants(all_instance_features(used_instance_idxs,:), 1);
    kept_X_columns = setdiff(1:nfeatures, constant_X_columns);

    is_cat_x = zeros(nfeatures,1);
    is_cat_x(xCat) = 1;
    is_cat_x = is_cat_x(kept_X_columns);
    xCat = find(is_cat_x);

    xCatDomains = xCatDomains(kept_X_columns);
	if isempty(kept_X_columns)
        all_instance_features = zeros(size(all_instance_features,1),1); % dummy instance feature
    else
        all_instance_features = all_instance_features(:,kept_X_columns);
    end    

    % we don't have feature names right now
    if ~isempty(names)
        for i=1:nfeatures
            names = [names; ['feature', num2str(i)]];
        end
    end
    
    %%
    if options.logModel == 1 || options.logModel == 3
        y = log10(y);
    end
    
    %%
    numPCA = options.pca;
    [pcaed_instance_features, sub, means, stds, pcVec] = do_pca(all_instance_features, numPCA);

    %%
    isclean = 1;
else 
    pcaed_instance_features = all_instance_features;
end

bout(sprintf(strcat(['Learning model with ', num2str(size(Theta_inst_idxs,1)), ' data points of dimension ', num2str(size(Theta, 2) + size(pcaed_instance_features, 2)),' ... \n'])));

%% === Wrapper around initializing a model and then preparing it for prediction.
model = initModel(Theta_inst_idxs, ThetaUniqSoFar, pcaed_instance_features, y, cens, thetaCat, thetaCatDomains, xCat, xCatDomains, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs, options, names);
if isempty(kept_Theta_columns) && isempty(kept_X_columns)
    model.constant = true;
    return;
end

model.kept_Theta_columns = kept_Theta_columns;
model.kept_X_columns = kept_X_columns;
model.numParameters = nvars;
model.numFeatures = nfeatures;
model.sub = sub;
model.means = means;
model.stds = stds;
model.pcVec = pcVec;
model.num_pca = numPCA;

% model.trainInstanceFeatures = pca_fwd(all_instance_features, model.sub, model.means, model.stds, model.pcVec, model.num_pca);
model.pcaed_instance_features = pcaed_instance_features;

if isfield(options, 'params_to_use')
    model.params = options.params_to_use;
else
    if (~isempty(strfind(options.modelType, 'GP')))  && ~isempty(find(cens, 1))
        %=== Optimizing a submodel without censored data.
        uncens_idx = find(cens==0);
        subModel = initModel(Theta_inst_idxs(uncens_idx,:), ThetaUniqSoFar, all_instance_features, y(uncens_idx), cens(uncens_idx), thetaCat, thetaCatDomains, xCat, xCatDomains, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs, options, names);
        subModel = optimizeModel(subModel, varargin{:});
        model.params = subModel.params;
% %     model.params = [-3;3];
%     model.params = [-2;3];
    else
        model = optimizeModel(model, varargin{:});
    end
end

model = prepareModel(model);
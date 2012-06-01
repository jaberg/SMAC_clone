function [yPred, yPredVar] = applyModel(model, X, isclean, observationNoise, joint)
if nargin < 5
    joint = 0;
end
if nargin < 4
    observationNoise = 0;
end
if nargin < 3
    isclean = 0;
end

if isfield(model,'constant')
    yPred = ones(size(X,1),1) * mean(model.y);
    yPredVar = ones(size(X,1),1) * var(model.y);
    yPredVar = max(yPredVar, model.options.min_variance);
    return
end
if ~isclean
    Theta = X(:, 1:model.numParameters);
    instanceFeatures = X(:, model.numParameters+1:end);
    
    Theta = Theta(:, model.kept_Theta_columns);
    
    if isempty(model.kept_X_columns)
        instanceFeatures = zeros(size(instanceFeatures,1),1); % dummy instance feature
    else
        instanceFeatures = instanceFeatures(:, model.kept_X_columns);
    end
    
    instanceFeatures = pca_fwd(instanceFeatures, model.sub, model.means, model.stds, model.pcVec, model.num_pca);
    
    X = [Theta, instanceFeatures];
    isclean = 1;
end

if isempty(strfind(model.type, 'GP'))
    error ('No such model type defined yet!');
end

global gprParams;
gprParams = [];
gprParams.combinedcat = model.cat;
gprParams.combinedcont = model.cont;
%             gprParams.algoParam = model.algoParam;

%=== Normalize X using same normalization as before:
%             X = X(:, model.good_feats);
%             X = X - repmat(model.means, [size(X,1),1]);
%             X = X ./ repmat(model.stds, [size(X,1),1]);

if isfield(model.options, 'ppSize') && model.options.ppSize > 0
    if joint
        error 'Joint predictions are not implemented yet for SRPP.'
    end

    %=== GP with subset of regressors or projected process
    [yPred, S2SR, S2PP] = gprSRPPfwd(model.Kmm, model.invKmm, model.saved_1, model.saved_2, model.params, model.covfunc, model.pp_index, model.X, X, observationNoise);
    yPredVar = S2PP;
    if (any(yPredVar < 0))
        debug_filename = 'debug_file_for_neg_var_in_pp.mat';
        bout(sprintf(strcat(['\n\nWARNING: predicted variance is negative: ', num2str(min(yPredVar)), ', saving workspace to ', debug_filename])));
        save(debug_filename);
    end
    yPredVar = max(yPredVar, 1e-10);
%                yPredVar = S2SR; % the two seem very similar, but the GP book suggests PP is better far away from the data.
else
    %=== Normal GP
    if isfield(model, 'useCensoring')
        [yPred, yPredVar] = gprCensorFwd(model.X, model.L_nonoise, model.alpha_nonoise, model.invK_times_invH_times_invK, model.covfunc, model.params, X, observationNoise, joint);
    else
        [yPred, yPredVar] = gprFwd(model.X, model.L, model.invL, model.alpha, model.covfunc, model.params, X, observationNoise, joint);
    end
end

yPredVar = max(yPredVar, model.options.min_variance);
if isfield(model, 'meanToAdd')
    yPred = yPred + model.meanToAdd;
end
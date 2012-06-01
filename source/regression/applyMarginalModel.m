function [yPred, yPredVar] = applyMarginalModel(model, thetaTest, instanceFeatures, isclean, observationNoise, joint)

if isfield(model,'constant')
    yPred = ones(size(thetaTest,1),1) * mean(model.y);
    yPredVar = ones(size(thetaTest,1),1) * var(model.y);
    yPredVar = max(yPredVar, model.options.min_variance);
    return
end
if nargin < 4
    isclean = 0;
end
if nargin < 5
    observationNoise = 0;
end
if nargin < 6
    joint = 0;
end
if ~isclean
    thetaTest = thetaTest(:,model.kept_Theta_columns);
end
if nargin < 3 || isempty(instanceFeatures)
    instanceFeatures = model.pcaed_instance_features;
    usingStoredFeatures = true;
    isclean = 1;
end
if ~isclean
    if isempty(model.kept_X_columns)
        instanceFeatures = zeros(size(instanceFeatures,1),1); % dummy instance feature
    else
    	instanceFeatures = instanceFeatures(:,model.kept_X_columns);
    end
    instanceFeatures = pca_fwd(instanceFeatures, model.sub, model.means, model.stds, model.pcVec, model.num_pca);
    isclean = 1;
end
    
if strcmp(model.type, 'rf')
    [yPred, yPredVar, treemeans] = compute_from_leaves(model.module, thetaTest, instanceFeatures);

    if model.options.logModel == 1
        treemeans = log10(treemeans);
    end
    yPred = mean(treemeans,2);
    yPredVar = var(treemeans,0,2);
    
elseif strcmp(model.type, 'javarf') || strcmp(model.type, 'fastrf')
	if strcmp(model.type, 'javarf')
        importstr = 'ca.ubc.cs.beta.models.rf.*';
	else
		importstr = 'ca.ubc.cs.beta.models.fastrf.*';
    end
    import(importstr);
    
    if usingStoredFeatures
        result = RandomForest.applyMarginal(model.P, thetaTest);
    else 
        result = RandomForest.applyMarginal(model.T, thetaTest, instanceFeatures);
    end
    yPred = result(:, 1);
    yPredVar = result(:, 2);
else
    if size(instanceFeatures, 1) == 1
        X = [thetaTest, repmat(instanceFeatures, size(thetaTest,1),1)];
        [yPred, yPredVar] = applyModel(model, X, isclean, observationNoise, joint);
        return;
    else
        error('Multiple instances => only random forest implemented.');
    end
end
yPredVar = max(yPredVar, model.options.min_variance);
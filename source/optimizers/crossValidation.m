function [rmse, ll, cc, y_cross, y_cross_var] = crossValidation(model)
% crossValidation(model)
% Evaluate the cross-validated likelihood of hold-out data
% under the predictive model.
% If we use the projected process approximation of GPs, keep the active set
% (index) fixed, and use it only as additional part of the training set for all folds.

k = min(model.options.crossVal_ll_k, length(model.y));
if k==1
    rmse = -1;
    ll = -1;
    cc = -1;
    y_cross = -1;
    y_cross_var = -1;
    return;
end

%=== Use the same seed here all the time, but don't affect outer seed.
s = rand('twister');
rand('twister',1234);
if model.options.ppSize > 0
    if length(model.y) <= model.options.ppSize + k
        error 'CV in the projected process approximation only done on the points outside the active set -- not enough of those available.'
    end
    indices_for_cv = setdiff(1:length(model.y), model.pp_index);
else
    indices_for_cv = 1:length(model.y);
end

N = length(indices_for_cv);
% if N == length(model.y)
%     randInd = 1:N;
% else
    randInd = randperm(N);
% end
rand('twister',s);

startIdx = 1;
for i=1:k
%    bout(strcat(['Cross-validation ', num2str(i), '/', num2str(k), '...\n']));
    endIdx = ceil(i*N/k);
    testInnerIdx = startIdx:endIdx;
    trainInnerIdx = setdiff(1:N, startIdx:endIdx);
    testIdx = indices_for_cv(randInd(testInnerIdx));
    trainIdx = indices_for_cv(randInd(trainInnerIdx));
    if model.options.ppSize > 0
        trainIdx = [model.pp_index, trainIdx];
    end
    
%     %=== Learn a tmpModel for that fold with the params from model, and predict.
%     tmpModel = initModel(model.origX(trainIdx,:), model.origY(trainIdx), model.cens(trainIdx), model.combinedcat, model.options, model.origNames, 1);
    
    tmpModel = subsetModel(model, trainIdx);
    %=== The indices of the active set need to be changed accordingly.
    if model.options.ppSize > 0
        tmpModel.pp_index = 1:length(model.pp_index); %since we pass the indices for the active set as the first elements of the training set.
    end
    
    tmpModel.params = model.params;

    if strcmp(model.type, 'BCM') || strcmp(model.type, 'mixture')
        %=== Use the same params in the subModel.
       for j = 1:length(tmpModel.module),
           tmpModel.module{j}.params = model.params;
       end
    end
    
    tmpModel.prepared = 0;
    if model.options.ppSize > 0
       %=== Cache inverse kernel of active set across folds.
        if i==1
            tmpModel = prepareModel(tmpModel);
            cached_invKmm = tmpModel.invKmm;
        else
            tmpModel = prepareModel(tmpModel, cached_invKmm);
        end
    else
        tmpModel = prepareModel(tmpModel);
    end
    [yPredMean, yPredVar] = applyModel(tmpModel, model.X(testIdx,:), 1);

    y_cross(testIdx,1) = yPredMean;
    y_cross_var(testIdx,1) = yPredVar;

    startIdx = endIdx + 1;
end
%if model.options.logModel
%    [rmse, ll, cc] = measures_of_fit(log10(model.y(indices_for_cv)), y_cross(indices_for_cv), y_cross_var(indices_for_cv), model.cens(indices_for_cv))
%else
    [rmse, ll, cc] = measures_of_fit(model.y(indices_for_cv), y_cross(indices_for_cv), y_cross_var(indices_for_cv), model.cens(indices_for_cv));
%end
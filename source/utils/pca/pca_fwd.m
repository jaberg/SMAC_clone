function pcaed_features = pca_fwd(features, sub, means, stds, pcVec, num_pca)
if num_pca == 0 || isempty(sub)
    features = zeros(size(features,1),0);
elseif num_pca > -1 && num_pca < size(features,2)
    N = size(features, 1);
    features = features(:,sub);
    features = features - repmat(means, [N,1]);
    features = features./repmat(stds, [N,1]);
    features = features*pcVec;
end
pcaed_features = features;
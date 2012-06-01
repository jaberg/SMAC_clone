function [all_pcaed_features_for_training_instances, sub, means, stds, pcVec] = do_pca(all_features_for_training_instances, num_pca)
all_pcaed_features_for_training_instances = all_features_for_training_instances;
stds = [];
sub = [];
means = [];
pcVec = [];

%=== Doing PCA here so the features for an instances are fixed throughout, but will do CV to fix the number of PCA components.
if num_pca == 0
    all_pcaed_features_for_training_instances = zeros(size(all_features_for_training_instances,1),0);
elseif num_pca > -1 && num_pca < size(all_features_for_training_instances,2)
    N = size(all_features_for_training_instances,1);
    %=== Normalize data.
    stds = std(all_features_for_training_instances,[],1);
    sub = find(stds>1e-5);
    if isempty(sub)
        all_pcaed_features_for_training_instances = zeros(size(all_features_for_training_instances,1),0);
        return
    end
    all_features_for_training_instances = all_features_for_training_instances(:,sub);
    means = mean(all_features_for_training_instances);
    all_features_for_training_instances = all_features_for_training_instances - repmat(means, [N,1]);
    stds = std(all_features_for_training_instances);
    all_features_for_training_instances = all_features_for_training_instances./repmat(stds, [N,1]);

    %=== Do PCA
    [pccoeff, pcVec] = pca(all_features_for_training_instances,num_pca);
    all_pcaed_features_for_training_instances = all_features_for_training_instances*pcVec;
end
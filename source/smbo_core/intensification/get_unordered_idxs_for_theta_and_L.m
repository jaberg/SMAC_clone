function idxs = get_unordered_idxs_for_theta_and_L(rundata, theta_idx, L, onlycens)
if nargin < 4
    onlycens = 0;
end
idx_for_theta = find(rundata.used_theta_idxs == theta_idx);
idxs = idx_for_theta( find(ismember( [rundata.used_instance_idxs(idx_for_theta), rundata.usedSeeds(idx_for_theta)], L, 'rows' )));
if onlycens % only return indices with censored runs.
    idxs = idxs( find(rundata.cens(idxs)) );
end

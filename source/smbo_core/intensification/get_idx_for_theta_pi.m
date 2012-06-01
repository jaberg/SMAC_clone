function idx_for_theta_pi = get_idx_for_theta_pi(rundata, theta_idx, pi_idx)
%=== Correct but slow:
% idx_for_theta_pi_seed = intersect( find(rundata.used_theta_idxs == theta_idxs(i)), ...
%     intersect( find(rundata.used_instance_idxs == pi_idxs(i)), ...
%     find(rundata.usedSeeds == seeds(i)) ) );

idx_for_theta = find(rundata.used_theta_idxs == theta_idx);
idx_for_theta_pi = idx_for_theta(rundata.used_instance_idxs(idx_for_theta) == pi_idx);
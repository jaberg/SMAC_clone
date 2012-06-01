function idx_for_theta_pi_seed = get_idx_for_theta_pi_seed(rundata, theta_idx, pi_idx, seed)
%=== Correct but slow:
% idx_for_theta_pi_seed = intersect( find(rundata.used_theta_idxs == theta_idxs(i)), ...
%     intersect( find(rundata.used_instance_idxs == pi_idxs(i)), ...
%     find(rundata.usedSeeds == seeds(i)) ) );

idx_for_theta_pi = get_idx_for_theta_pi(rundata, theta_idx, pi_idx);
idx_for_theta_pi_seed = idx_for_theta_pi(rundata.usedSeeds(idx_for_theta_pi) == seed); 

%=== Assert we only have a single run with the same theta, pi, and seed.
assert(length(idx_for_theta_pi_seed) <= 1);
function [pi_idx, captime, seed] = selectInstCaptimeSeedForIncStratified(incumbent_theta_idx, rundata, func)

idxs = find(rundata.used_theta_idxs == incumbent_theta_idx);

N = func.numTrainingInstances;
used_insts = rundata.used_instance_idxs(idxs);
used_insts = [used_insts; N; 1]; % artificially expand used instances by 1 and N, so that hist produces one bin per instance.

inst_counts = hist(used_insts, N);
inst_counts(1) = inst_counts(1)-1; % remove the 2 artificial instance counts
inst_counts(N) = inst_counts(N)-1;

min_count = min(inst_counts);
min_idxs = find(inst_counts==min_count);
pi_idx = min_idxs(ceil(rand*length(min_idxs)));

my_idxs = idxs(find(rundata.used_instance_idxs(idxs)==pi_idx));

possible_seeds = func.seeds(pi_idx,:);
used_seeds = rundata.usedSeeds(my_idxs);
possible_seeds = setdiff(possible_seeds, used_seeds);
seed = possible_seeds(ceil(rand*length(possible_seeds)));

captime = rundata.kappa_max;
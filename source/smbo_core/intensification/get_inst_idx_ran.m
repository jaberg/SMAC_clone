function insts = get_inst_idx_ran(theta_idx, rundata)

%=== Get rundata indices and used instances for the incumbent configuration.
idxs = find(rundata.used_theta_idxs == theta_idx);
insts = unique(rundata.used_instance_idxs(idxs));

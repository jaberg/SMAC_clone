function [numNew, numInc, numIntersect, newGotAll, obj_new_lb, obj_inc, common_inst_seeds, neededInstSeeds, full_obj_inc, singleRunObjectives_new_lb, singleRunObjectives_inc, ys_new, ys_inc] = compareToIncBlockOnlyInst(theta_new_idx, incumbent_theta_idx, rundata, al_opts, func)
%=== Compare challenger configuration against incumbent. 
%=== Assert that for incumbent there are no censored runs below the global captime.
%=== For challenger censored runs are ok, only evaluate a lower bound.

%=== Get rundata indices and used instances for the incumbent configuration.
inc_idxs = find(rundata.used_theta_idxs == incumbent_theta_idx);
inc_insts = unique(rundata.used_instance_idxs(inc_idxs));

%=== Get rundata indices and used instances for the new configuration.
new_idxs = find(rundata.used_theta_idxs == theta_new_idx);
new_insts = unique(rundata.used_instance_idxs(new_idxs));
if isempty(new_insts)
    new_insts = zeros(0,1);
end

%=== Get (instance,seed) combinations for the incumbent configuration.
incumbent_inst_seeds = [rundata.used_instance_idxs(inc_idxs), rundata.usedSeeds(inc_idxs)];
numInc = size(incumbent_inst_seeds, 1);

%=== Get (instance,seed) combinations for the new configuration.
new_inst_seeds = [rundata.used_instance_idxs(new_idxs), rundata.usedSeeds(new_idxs)];
numNew = size(new_inst_seeds, 1);
if isempty(new_inst_seeds)
    new_inst_seeds = zeros(0,2);
end

%=== Get intersection and set difference in (instance,seed) combos.
common_inst_seeds = intersect(incumbent_inst_seeds, new_inst_seeds, 'rows');
neededInstSeeds = setdiff(incumbent_inst_seeds, new_inst_seeds, 'rows');
numIntersect = size(common_inst_seeds, 1);
newGotAll = (numIntersect == numInc);

%=== Compute lower bound for new configuration on the common instances.
common_insts = intersect(inc_insts, new_insts);
%=== Fix 29/07: Need to work on the [instance, seed] combinations to get a true lower bound
% obj_new_lb = get_objective_for_insts(theta_new_idx, rundata, common_insts, al_opts.overallobj, func);
obj_new_lb = lb_for_L(rundata, theta_new_idx, common_inst_seeds, al_opts, func, 1);
assert(~isnan(obj_new_lb), 'obj_new_lb cannot be NaN.');

%=== Compute exact objective for new configuration on the common instances
%=== (based on current runs; no cutoffs below kappa_max!) and on all instances
obj_inc = get_objective_for_insts(incumbent_theta_idx, rundata, common_insts, al_opts.overallobj, func, 1);
assert(~isnan(obj_inc), 'obj_inc cannot be NaN.');
full_obj_inc = get_objective_for_insts(incumbent_theta_idx, rundata, inc_insts, al_opts.overallobj, func, 1);
assert(~isnan(full_obj_inc), 'full_obj_inc cannot be NaN.');

[singleRunObjectives_new_lb, ys_new] = getSingleObjectives(new_idxs, rundata, common_inst_seeds, al_opts.overallobj, func);
%[singleRunObjectives_new_lb_saved, ys_new] = saved_getSingleObjectives(new_idxs, rundata, common_inst_seeds, al_opts.overallobj, func);
%for i=1:length(singleRunObjectives_new_lb)
%    assert(abs(singleRunObjectives_new_lb_saved(i)-singleRunObjectives_new_lb(i))<1e-6);
%end

[singleRunObjectives_inc, ys_inc] = getSingleObjectives(inc_idxs, rundata, common_inst_seeds, al_opts.overallobj, func, 1);
%[singleRunObjectives_inc_saved, ys_new] = saved_getSingleObjectives(inc_idxs, rundata, common_inst_seeds, al_opts.overallobj, func);
%for i=1:length(singleRunObjectives_inc)
%    assert(abs(singleRunObjectives_inc_saved(i)-singleRunObjectives_inc(i))<1e-6);
%end
function obj_lb = get_objective_for_insts(theta_idx, rundata, insts, overallobj, func, assertNonCapped)
%=== This function yields a lower bound on the combined runtime of theta_idx on instances insts w.r.t to the runs in rundata.

if nargin < 6
    assertNonCapped = 0;
end
assert(assertNonCapped==1, 'Changed meaning: can only call this function with assertions that all runs exist.')
if isempty(insts)
    obj_lb = 0;
    return;
end

sum_obj_lb = 0;
idx_for_theta = find(rundata.used_theta_idxs == theta_idx);
for i=1:length(insts)
    pi_idx = insts(i);
    idxs = idx_for_theta( find(rundata.used_instance_idxs(idx_for_theta)==pi_idx) );
%    assert(~isempty(idxs), 'This procedure should only be called for a subset of the instances a config has already been run on');
    if isempty(idxs)
        continue % if there is no run for an instance, we count the lower bound of 0
    end
    ys = rundata.y(idxs);
    if assertNonCapped
        assert( isempty(intersect( find(rundata.cens(idxs)==1), find(rundata.y(idxs) < func.cutoff-1e-6) )) ); % if we capped a run early, we need to re-run it for the comparison!
    end
    sum_obj_lb = sum_obj_lb + combineRunObjectives(overallobj, ys(:)', func.cutoff);
end
obj_lb = sum_obj_lb/length(insts);
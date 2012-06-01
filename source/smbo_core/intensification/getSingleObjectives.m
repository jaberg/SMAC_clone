function [single_objectives_lb,ys_lb] = getSingleObjectives(idxs, rundata, L, overallobj, func, assertNonCapped)
if isempty(L)
    single_objectives_lb = [];
    ys_lb = [];
    return;
end
if nargin < 6
    assertNonCapped = 0;
end

[tmp, sortidx] = sort(L(:,1)*1e20 + L(:,2));
L = L(sortidx,:);

idx_for_theta = idxs;

%=== Get index of all runs of theta on instance/seed combos in L.
idx = idx_for_theta( find(ismember( [rundata.used_instance_idxs(idx_for_theta), rundata.usedSeeds(idx_for_theta)], L, 'rows' )));
if assertNonCapped
    assert(length(idx) == size(L,1));
    assert( isempty(intersect( find(rundata.cens(idx)==1), find(rundata.y(idx) < func.cutoff-1e-6) )) ); % if we capped a run early, we need to re-run it for the comparison!
end

%=== idx holds all the indices we need, but not in the order of L, so fix that
L_done = [rundata.used_instance_idxs(idx), rundata.usedSeeds(idx)];
[tmp, sortidx] = sort(L_done(:,1)*1e20 + L_done(:,2));
idx_sorted = idx(sortidx,:);

%=== idx_sorted is in the order of L, but doesn't need to have all of them.
%=== Go through L, use existing runs and 0 for non-existing ones.
ys_lb = zeros(size(L,1),1);
running_idx = 1;
for i=1:size(L,1)
    if running_idx <= length(idx_sorted)
        next_idx = idx_sorted(running_idx);
        if rundata.used_instance_idxs(next_idx) == L(i,1) && rundata.usedSeeds(next_idx) == L(i,2) 
            ys_lb(i) = rundata.y(next_idx);
            running_idx = running_idx+1;
        else
            ys_lb(i) = 0;
        end
    else
        ys_lb(i) = 0;
    end
end

single_objectives_lb = combineRunObjectives(overallobj,ys_lb(:), func.cutoff);
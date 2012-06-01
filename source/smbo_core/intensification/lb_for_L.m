function qual = lb_for_L(rundata, theta_idx, L, al_opts, func, onlyBlockingOnInst)
%% lb_for_L
%=== Hallucinate perfect expansion of the runs we don't yet have for L.
for i=1:size(L,1)
    idx = get_idx_for_theta_pi_seed(rundata, theta_idx, L(i,1), L(i,2));
    if isempty(idx) % run doesn't exist so far => we make a new perfect entry in rundata
        idx = length(rundata.y)+1;
        rundata.y(idx) = 0;
        rundata.cens(idx) = 0;
        rundata.used_theta_idxs(idx) = theta_idx;
        rundata.used_instance_idxs(idx) = L(i,1);
        rundata.usedSeeds(idx) = L(i,2);
    else
        % we say it's successful with exactly the captime used before
        rundata.cens(idx) = 0;
    end
end
if onlyBlockingOnInst
    insts = unique(L(:,1));
    qual = get_objective_for_insts(theta_idx, rundata, insts, al_opts.overallobj, func, 1);
else
    error 'Code for blocking on both instances and seeds is old and not maintained.'
%     qual = get_objective(theta_idx, rundata, L, al_opts.overallobj, func);
end
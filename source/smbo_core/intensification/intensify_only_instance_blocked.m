function [rundata, bestconflist, incumbent_theta_idx] = intensify_only_instance_blocked(model, func, iteration, rundata, incumbent_theta_idx, theta_new_idx, bestconflist, al_opts)
%=== New blocked comparison: select (instance, seed) combination from the ones of the incumbent.
global ThetaUniqSoFar;

%=== Do one new run for incumbent if less than maxN. (Could make this contingent on some stronger condition.)
%=== Do this in a randomized order, but such that we never use one instance
%=== more than once more than another.
idxs = find(rundata.used_theta_idxs == incumbent_theta_idx);
al_opts.maxn = min(al_opts.maxn, func.numTrainingInstances*size(func.seeds,2));
if length(idxs) < al_opts.maxn
    [pi_idx, captime, seed] = selectInstCaptimeSeedForIncStratified(incumbent_theta_idx, rundata, func);
    rundata = dorun(func, incumbent_theta_idx, pi_idx, captime, seed, iteration, rundata);
end

if theta_new_idx == incumbent_theta_idx
    return;
end

upToNumNewRuns = 1;
while 1
    %=== Evaluate how challenger compares to incumbent.
    [numNew, numInc, numIntersect, newGotAll, obj_new_lb, obj_inc, common_inst_seeds, neededInstSeeds] = compareToIncBlockOnlyInst(theta_new_idx, incumbent_theta_idx, rundata, al_opts, func);

    %=== Make comparison based on common runs and numNewRuns from inc.L \new.L (as many as there are)
%    if isempty(neededInstSeeds)
%        L = common_inst_seeds;
%    else
        perm = randperm(size(neededInstSeeds,1));
        L = union(common_inst_seeds, neededInstSeeds(perm(1:min(upToNumNewRuns,length(perm))),:), 'rows');
%    end
    
    % Changed by FH 27/07: want to base the comparison on L only, not the
    % rest of incumbent's instances
    % Was: insts = get_inst_idx_ran(incumbent_theta_idx, rundata);
    insts = unique(L(:,1));
    if al_opts.adaptive_capping
        bound = get_objective_for_insts(incumbent_theta_idx, rundata, insts, al_opts.overallobj, func, 1) + 1e-3;
    else
        bound = inf;
    end
    bout(sprintf('Performing up to %d run(s) for challenger %d up to a total bound %f on %d instances.\n', min(upToNumNewRuns,length(perm)), theta_new_idx, bound, length(insts)));
    rundata = doBoundedRuns(rundata, theta_new_idx, L, bound, func, al_opts, iteration, 1);
   
    %=== Evaluate how challenger compares to incumbent.
    [numNew, numInc, numIntersect, newGotAll, obj_new_lb, obj_inc] = compareToIncBlockOnlyInst(theta_new_idx, incumbent_theta_idx, rundata, al_opts, func);
    
    bout(sprintf('Based on the runs on their %d shared instances, challenger %d has lower bound %f and incumbent %d has obj %f.\n', numIntersect, theta_new_idx, obj_new_lb, incumbent_theta_idx, obj_inc));

    %=== New one is worse => stop.
    if (obj_new_lb > obj_inc + 1e-6) % challenger is worse
        bout(sprintf('Based on %d runs, challenger %d is worse (lb on obj %f) than incumbent %d (obj %f) -> stopping its evaluation.\n', numIntersect, theta_new_idx, obj_new_lb, incumbent_theta_idx, obj_inc));
        return;
    end

    if newGotAll
        %=== New one has all runs and is not worse => if tie stay with old one, otherwise make new one incumbent.
        if obj_new_lb < obj_inc - 1e-6 % <
            bout(sprintf('Challenger %d has all the %d runs of the incumbent %d and has better objective (%f as opposed to %f) -> making it new incumbent.\n', theta_new_idx, numInc, incumbent_theta_idx, obj_new_lb, obj_inc));
            
            % Correct, but slow: cens_idx = intersect( find(rundata.used_theta_idxs == theta_new_idx), ...
            % intersect( find(rundata.cens), find(rundata.used_captimes < func.cutoff-1e-6) ) );
            idx_for_theta = find(rundata.used_theta_idxs == theta_new_idx);
            idx_for_theta_cens = idx_for_theta(find(rundata.cens(idx_for_theta)));
            cens_idx = idx_for_theta_cens(find(rundata.used_captimes(idx_for_theta_cens) < func.cutoff-1e-6)); 
            if ~isempty(cens_idx)
                bout(sprintf('ERROR: got runs for theta becoming incumbent that are censored below the threshold'));
                idx_for_theta
                idx_for_theta_cens
                rundata.used_captimes(idx_for_theta_cens)
                func.cutoff-1e-6
                cens_idx
                error_workspace = 'error_new_inc_has_censored_runs.mat'
                save(error_workspace);
                error('ERROR: got runs for theta becoming incumbent that are censored below the threshold');
            end
    
            incumbent_theta_idx = theta_new_idx;
            %=== Set bestconflist from here onwards to new incumbent
            if length(rundata.used_theta_idxs) > length(bestconflist)
                m = length(rundata.used_theta_idxs) - length(bestconflist);
                bestconflist(end+1:end+m-1) = bestconflist(end);
                bestconflist(length(rundata.used_theta_idxs)) = incumbent_theta_idx;
            else
                bestconflist(length(rundata.used_theta_idxs):end) = incumbent_theta_idx;
            end
        else
            bout(sprintf('Challenger %d has all the %d runs of the incumbent %d, but doesn''t have better objective (%f as opposed to %f) -> stopping its evaluation.\n', theta_new_idx, numInc, incumbent_theta_idx, obj_new_lb, obj_inc));
        end
        return;
    end
    
    upToNumNewRuns = upToNumNewRuns*2;
end
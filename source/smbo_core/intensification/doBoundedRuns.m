function rundata = doBoundedRuns(rundata, theta_idx, L, bound, func, al_opts, iteration, onlyBlockingOnInst)
%% doBoundedRuns
if nargin < 8
    onlyBlockingOnInst = 0;
end
%=== If theta does not have a chance to become better than bound based on existing runs, stop.
if lb_for_L(rundata, theta_idx, L, al_opts, func, onlyBlockingOnInst) >= bound
    return;
end

%=== Get idxs for existing censored runs of theta on L.
idxs = get_unordered_idxs_for_theta_and_L(rundata, theta_idx, L, 1);

%=== First, go through existing runs and extend their captime.
%=== This will change idxs, so we need to recompute them every time.
%=== While the lower bound for the current theta is below the bound and
%=== there are capped runs, continue.

changed = 1;
while changed
    changed = 0;
    for i=1:length(idxs)
        idx = idxs(i);
        if rundata.cens(idx) && rundata.used_captimes(idx) < func.cutoff-1e-6
            %=== Redo run with higher captime.
            pi_idx = rundata.used_instance_idxs(idx);
            seed = rundata.usedSeeds(idx);

            rundata = more_detail(rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, iteration, idx, onlyBlockingOnInst);
            if lb_for_L(rundata, theta_idx, L, al_opts, func, onlyBlockingOnInst) >= bound
                return;
            end
            % FH: Sept 08, 2011, I don't think we can assert this; we may
            % well have a run that's censored with a larger captime.
            %             assert( ~(rundata.cens(idx) && rundata.used_captimes(idx) < func.cutoff-1e-6), ...
%                    'The previously censored run must either not be censored anymore after re-running, or censored at the max captime');

%             Old code that was needed with old version of doRun (now not needed anymore since we replace capped runs in place)
%             %=== Recompute idxs after they changed due to last run.
%             idxs = get_unordered_idxs_for_theta_and_L(rundata, theta_idx, L, 1);
%             changed = 1;
%             break;
        end
    end
end

%=== Now, do new runs.
%=== Get idxs for existing runs of theta on L.
idxs = get_unordered_idxs_for_theta_and_L(rundata, theta_idx, L);

non_existing_L = L;
existing_L = [rundata.used_instance_idxs(idxs), rundata.usedSeeds(idxs)];
if ~isempty(existing_L)  
    non_existing_L = setdiff(L, existing_L, 'rows');
end
if isempty(non_existing_L)
    return
end

if isinf(bound)
    %=== Just do all the runs with maximal captime.
    theta_idx_vec = theta_idx * ones(size(non_existing_L,1), 1);
    pi_idx_vec = non_existing_L(:,1);
    seed_vec = non_existing_L(:,2);
    captime_vec = func.cutoff * ones(size(non_existing_L,1), 1);
    rundata = dorun(func, theta_idx_vec, pi_idx_vec, captime_vec, seed_vec, iteration, rundata);
else
    %=== While the lower bound for the current theta is below the bound and
    %=== we don't have all runs yet, continue.
    for i=1:size(non_existing_L,1)
        rundata = more_detail(rundata, theta_idx, non_existing_L(i,1), non_existing_L(i,2), L, bound, al_opts, func, iteration, [], onlyBlockingOnInst);
        if lb_for_L(rundata, theta_idx, L, al_opts, func, onlyBlockingOnInst) >= bound
            return;
        end
    end
end


function rundata = more_detail(rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, iteration, existing_idx, onlyBlockingOnInst)
%% more_detail
insts = unique(L(:,1));
sum_bound = bound * length(insts);

switch al_opts.overallobj
    case {'mean', 'mean10'} % Special-case code for these objectives.
        %=== Get the list of instances/seeds to base the comparison on,
        %=== next to the current instance/seed combination
        L_rest = setdiff(L, [pi_idx, seed], 'rows');
        insts_rest = unique(L_rest(:,1));

        %=== Get the instances to base the comparison on, other than pi_idx, 
        %=== and the contribution of these instances to the objective.
        insts_without_pi = setdiff(insts_rest, pi_idx);
        if isempty(insts_without_pi)
            obj_contribution_rest = 0;
        else 
            L_without_inst = L_rest(L_rest(:,1)~=pi_idx,:);
            obj_contribution_rest = length(insts_without_pi) * lb_for_L(rundata, theta_idx, L_without_inst, al_opts, func, onlyBlockingOnInst);
        end

        %=== Get the contribution for this instance to the objective.
        idxs = get_idx_for_theta_pi(rundata, theta_idx, pi_idx);
        N = length(idxs);
        if N==0 %=== Start a new instance for the challenger
            currentSumThisInstance = 0; 
        else %=== Get more detail for an existing instance for the challenger
            currentSumThisInstance = N * combineRunObjectives(al_opts.overallobj, rundata.y(idxs)', func.cutoff);
        end

        %=== Set the captime so that if it is reached the new configuration
        %=== is just worse than the bound.
        allowedMeanThisInstance = sum_bound - obj_contribution_rest;
        numOccurencesOfInstInL = length(find(L(:,1)==pi_idx));
        allowedSumThisInstance = allowedMeanThisInstance * numOccurencesOfInstInL; % we are comparing with respect to all the runs of inst in L we have
        
        if ~isempty(existing_idx)
            %=== If we already did the run and it timed out, we will replace it, so don't double-count its runtime.
            currentSumThisInstance = currentSumThisInstance-rundata.y(existing_idx);
        end
        
        captime = allowedSumThisInstance - currentSumThisInstance + 1e-3;
        captime = min(captime, func.cutoff);
%         fprintf('asserting captime same as binary search...\n');
%         captime2 = binary_search_for_critical_captime(0, al_opts.kappa_max, rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, onlyBlockingOnInst);
%         captime2 = min(captime2, func.cutoff);
%         assert(abs(captime2-captime) < 1e-5);
        
    otherwise
        %=== Find the minimal captime with which the configuration gest just worse than the bound.
        captime = binary_search_for_critical_captime(0, al_opts.kappa_max, rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, onlyBlockingOnInst);
end

assert(captime > 0, 'Computed captime must be >0 (we add 1e-3)');

captime = captime * al_opts.cap_slack;
%=== If we ran this theta,pi,seed combo before, at least double the runtime
%=== to avoid increasing the captimes by epsilon each time.
if ~isempty(existing_idx)
    assert(rundata.cens(existing_idx)==1, 'We should never try to redo a successful run.');
    captime = max(captime, rundata.used_captimes(existing_idx)*2); 
end
captime = min(captime, func.cutoff);

if captime < func.cutoff
    captime
end
%=== Perform a run with the appropriate captime.
rundata = dorun(func, theta_idx, pi_idx, captime, seed, iteration, rundata);


%=== Binary search over captimes to find the minimal one that will
%=== disqualify theta_idx even if successful.
function captime = binary_search_for_critical_captime(min_y, max_y, rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, onlyBlockingOnInst)
%% binary_search_for_critical_captime
mean_y = (min_y+max_y)/2;
if (max_y - min_y < 1e-6)
    captime = max_y + 1e-3; % some slack so it is definitely bad if it times out.
    return;
end
if qual_with_hallucinated_y(mean_y, rundata, theta_idx, pi_idx, seed, L, al_opts, func, onlyBlockingOnInst) > bound
    % if the run takes mean_y, that's already too long.
    captime = binary_search_for_critical_captime(min_y, mean_y, rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, onlyBlockingOnInst);
else
    captime = binary_search_for_critical_captime(mean_y, max_y, rundata, theta_idx, pi_idx, seed, L, bound, al_opts, func, onlyBlockingOnInst);
end


function qual = qual_with_hallucinated_y(y, rundata, theta_idx, pi_idx, seed, L, al_opts, func, onlyBlockingOnInst)
%% qual_with_hallucinated_y
%=== Hallucinate a new uncensored runtime and evaluate the objective.
%=== If rundata already contains a run, we'll overwrite that run.
if size(L,1) >= 3
    L;
end
idx = get_idx_for_theta_pi_seed(rundata, theta_idx, pi_idx, seed);
if isempty(idx) % run doesn't exist so far => we make a new perfect entry in rundata
    idx = length(rundata.y)+1;
end
rundata.y(idx) = y;
rundata.cens(idx) = 0;
rundata.used_theta_idxs(idx) = theta_idx;
rundata.used_instance_idxs(idx) = pi_idx;
rundata.usedSeeds(idx) = seed;

qual = lb_for_L(rundata, theta_idx, L, al_opts, func, onlyBlockingOnInst);
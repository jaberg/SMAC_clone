function [ei_challengers, eiTime, valStats] = select_challengers_with_EI(func, model, means, vars, incumbent_theta_idx, options, valdata, valStats, rundata, learnTime)
global ThetaUniqSoFar;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SELECT F_MIN_SAMPLES FOR THE EI CRITERION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch options.ei_inc
    case 0 %'inc'
        %=== Doing expected improvement OVER THE DISTRIBUTION OF THE INCUMBENT
        s1 = randn('state');
        f_min_samples = means(incumbent_theta_idx) + sqrt(vars(incumbent_theta_idx)) * randn(options.N_s,1);
        randn('state', s1);
        %        f_min_samples = f_min_samples(find(f_min_samples>=0));
    case 2 % 'spo'
        idx_inc = find(rundata.used_theta_idxs==incumbent_theta_idx);
        f_min_samples = combineRunObjectives(options.overallobj, rundata.y(idx_inc(:))', func.cutoff);
        if options.logModel == 1 || options.logModel == 3
            f_min_samples = log10(f_min_samples);
        end
    case 3 %'inc_ucb' % thought SKO was using this, but it isn't
        f_min_samples = means(incumbent_theta_idx) + sqrt(vars(incumbent_theta_idx));
    case 4 %'inc_sko' % this is what SKO is using, where the incumbent is the min of mean+std
        f_min_samples = means(incumbent_theta_idx);

    otherwise
        error (strcat('Unknown EI inc criterion options.ei_inc: ', num2str(options.ei_inc)))
end

valStats = plotsForValidatingModel_with_ei(options, model, f_min_samples, valdata, valStats, rundata);
if options.just_valid
    ei_challengers = [];
    eiTime = -1;
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIMIZATION OF EXPECTED IMPROVEMENT TO SELECT CONFIGURATION TO RUN NEXT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bout(sprintf('Optimizing EI at valdata.iteration %d ...\n', [valdata.iteration]));
tic;
funcHandle = @(theta) neg_ei_of_model(theta, model, options.expImpCriterion, f_min_samples);
negEiThetaUniqSoFar = funcHandle(ThetaUniqSoFar);
eiPreviousTime = toc;
bout(sprintf('Compute negEI for all conf. seen at valdata.iteration %d: took %f s\n', [valdata.iteration, eiPreviousTime]));

[tmp, sorted_theta_idxs] = sort(negEiThetaUniqSoFar);

%=== Initial configurations: the 10 previous highest-scoring ones, and 0 random ones
numStartConfigs = options.numLSbest;
numPrevConfigs = numStartConfigs;
theta_seed_configs = ThetaUniqSoFar(sorted_theta_idxs(1:min(numPrevConfigs, size(ThetaUniqSoFar,1))), :);
%theta_seed_configs = [theta_seed_configs; selectRandomConfigs(func, numStartConfigs)];


%=== Local search from initial configurations.
domains_for_ls = {};
for param=func.cat
    domains_for_ls{param} = 1:func.num_values(param); %#ok<AGROW>
end

min_neg = inf;
for i=1:size(theta_seed_configs,1)
    thisStartTime = toc;
    cond_params_idxs = func.cond_params_idxs;
    parent_param_idxs = func.parent_param_idxs;
    ok_parent_value_idxs = func.ok_parent_value_idxs;
    if options.ignore_conditionals
        cond_params_idxs = [];
        parent_param_idxs = [];
        ok_parent_value_idxs = {};
    end
    [a, b] = general_basic_local_search_mixed_disc_cont(funcHandle, theta_seed_configs(i,:), func.cat, domains_for_ls, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs);
    new_theta_configs(i,:) = a; %#ok<AGROW>
    neg_ei_of_ls(i) = b; %#ok<AGROW>
    if neg_ei_of_ls < min_neg 
        min_neg = neg_ei_of_ls(i);
    end
    thisTime = toc - thisStartTime;
    bout(sprintf('LS %d took %f seconds and yielded neg log EI %f\n', [i, thisTime, neg_ei_of_ls(i)]));
end

new_theta_configs = [new_theta_configs; selectRandomConfigs(func, options.numRandomInEiOpt)];

[neg_ei_new, predmean_new, predvar_new] = neg_ei_of_model(new_theta_configs, model, options.expImpCriterion, f_min_samples);
eiTime = toc;
eiTime = eiTime + eiPreviousTime;
bout(sprintf('Optimization of EI at valdata.iteration %d: took %f s\n', [valdata.iteration, eiTime]));


[tmp, neg_ei_new_sort_idx] = mysort(neg_ei_new); % not preserving order
[tmp, mean_new_sort_idx] = sort(predmean_new);
bestmean_idx = mean_new_sort_idx(1);
bout(sprintf('f_min_samples = %f\n', f_min_samples));
bout(sprintf('Rank of mean of top EI: %d (%f +/- %f); config with min. pred mean: %f +/- %f, EI=%f\n', [1+length(find(predmean_new < predmean_new(neg_ei_new_sort_idx(1)) )), predmean_new(neg_ei_new_sort_idx(1)), sqrt(predvar_new(neg_ei_new_sort_idx(1))), predmean_new(bestmean_idx), sqrt(predvar_new(bestmean_idx)), -neg_ei_new(neg_ei_new_sort_idx(1)) ]));

ei_challengers = new_theta_configs(neg_ei_new_sort_idx,:);

%=== Output top predicted challengers.
num_output = size(ei_challengers,1) - options.numRandomInEiOpt;
for num_challenger=1:num_output
    [ei_c, predmean_c, predvar_c] = neg_ei_of_model(ei_challengers(num_challenger,:), model, options.expImpCriterion, f_min_samples);
    bout(sprintf('Challenger %d: predicted %f +/- %f, expected improvement %f\n', [num_challenger, predmean_c, sqrt(predvar_c), -ei_c]));
end

function [sorted, sort_idx] = mysort(array)
%=== Just like sort, but NOT preserving order -- instead random tie breaking
perm = randperm(length(array));
arrayperm = array(perm);
arrayperm = arrayperm(:);
[sorted, sort_idx_perm] = sort(arrayperm);
sort_idx(:,1) = perm(sort_idx_perm);

sorted = reshape(sorted, size(array));
sort_idx = reshape(sort_idx, size(array));
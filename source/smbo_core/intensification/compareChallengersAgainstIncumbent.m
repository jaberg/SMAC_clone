function [incumbent_theta_idx, bestconflist, rundata] = compareChallengersAgainstIncumbent(challengers, incumbent_theta_idx, model, func, rundata, iteration, minRawAlgoTime, al_opts, alTunerTime, iterationTime, bestconflist)
% Function comparing challengers to the incumbent by performing runs on them. 
global allParamStrings;

for num_challenger = 1:size(challengers,1)
    if have_to_stop(alTunerTime, rundata.runTime, func, rundata.used_instance_idxs, al_opts, iteration)
        break
    end
    if num_challenger > 2
        %=== If we have already run all the configs we want to run,
        %we might still have to run longer to do *some* runs rather
        %than spending all time with the reasoning.
        if (rundata.runTime(iteration+1) > minRawAlgoTime)
            break
        elseif rundata.runTime(iteration+1) > 0
            bout(sprintf('So far, spent %f seconds of raw target algorithm time in this iteration. Running up to %f seconds\n', [rundata.runTime(iteration+1), minRawAlgoTime]));
        end
    end

    %=== Put challenger into ThetaUniqSoFar and get its index.
    theta_new_idx = update_if_new_param_config(func, challengers(num_challenger,:));
    bout(sprintf('Challenger %d', num_challenger));
    if mod(num_challenger, 2)==1
        bout(sprintf(' --- EI configuration)\n'));
    else
        bout(sprintf(' --- random configuration)\n'));
    end

    switch al_opts.intens_schedule
        case 7 % blocking only on instances
            [rundata, bestconflist, incumbent_theta_idx] = ...
                intensify_only_instance_blocked(model, func, iteration, rundata, incumbent_theta_idx, theta_new_idx, bestconflist, al_opts);
            
        otherwise error('unknown intens_schedule in compareChallengersAgainstIncumbent.m')
    end
    %=== Update history of incumbents and output this one.
    new_best_paramstring = allParamStrings{incumbent_theta_idx};
    %== Get empirical mean and variance of the mean to output.
    data = rundata.y(rundata.used_theta_idxs==incumbent_theta_idx)';
    meanInc = combineRunObjectives(al_opts.overallobj, data, func.cutoff);
    if al_opts.logModel == 1 || al_opts.logModel == 3
        meanInc = log10(meanInc);
    end
    stdInc = -1; % sqrt( var(data) / length(data));        
    outputNewBest(sum(rundata.runTime), meanInc, stdInc, incumbent_theta_idx, alTunerTime, iterationTime, new_best_paramstring, length(find(rundata.used_theta_idxs==incumbent_theta_idx)),length(rundata.used_theta_idxs), iteration);
end
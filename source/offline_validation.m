function offline_validation(func, options, bestconflist, incumbent_theta_idx)
    %=== Offline analysis of SMBO's result.
    bout(sprintf(strcat('SMBO finished. Now evaluating configurations on the test set...\n')));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EVALUATION AT END
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global incumbent_matrix;
    global ThetaUniqSoFar;
    global allParamStrings; %#ok<NUSED> % needed for actually doing runs.

    if options.totalNumRunLimit >= 1
        rep = 100; % only relevant for matlab fun

        if options.evalTimesIncumbents
            eval_time = 10;
            result_matrix = [];
            testquals = inf * ones(size(ThetaUniqSoFar,1), 1);
            while 1
                %=== Compute test performance.
                idx = find(incumbent_matrix(:,1) <= eval_time + 1e-4);
                idx = idx(end);
                theta_idx = incumbent_matrix(idx,3);
                bout(sprintf('Evaluating config id %d...', theta_idx));
                if isinf(testquals(theta_idx))
                    testquals(theta_idx) = getTruePerformance(func, theta_idx, (1:func.numTestInstances)');
                end
                result_matrix = [result_matrix; [eval_time, incumbent_matrix(idx,2), testquals(theta_idx), incumbent_matrix(idx,4)]]; %#ok<AGROW>

                bout(sprintf('Config id %d for time point %f got test quality %g using %d runs.\n', [theta_idx, eval_time, testquals(theta_idx), func.numTestInstances]));

                if eval_time >= func.tuningTime - 1e-4
                    break
                end
                eval_time = min(eval_time * 2, func.tuningTime);
            end
            csvwrite(options.valall_filename, result_matrix);

        elseif options.evalAllIncumbents % output full trajectory
            uniqbestconflist = unique(bestconflist);
            uniqbestconflist = setdiff(uniqbestconflist, -1);
            qual=zeros(max(uniqbestconflist),1);
            for j=1:length(uniqbestconflist)
                conf_id = uniqbestconflist(j);

                actualObjTest = getTruePerformance(func, conf_id, (1:func.numTestInstances)');
                qual(conf_id) = actualObjTest;

                bout(sprintf('Config id %d got test quality %g using %d runs.\n', [conf_id, actualObjTest, rep]));
            end

            qual_at = qual(bestconflist);
            qual_at = qual_at(:);
            if ~isdeployed
                figure(2)
                semilogy(1:length(bestconflist), qual_at);
            end
            algorunNums = 1:length(bestconflist);
            csvwrite(valall_filename, [algorunNums(:), qual_at(:)]);
        else
            actualObjTest = getTruePerformance(func, incumbent_theta_idx, (1:func.numTestInstances)');
            csvwrite(options.val_filename, [length(bestconflist), actualObjTest]);

            bout(sprintf('Config id %d got test quality %g using %d runs.', [incumbent_theta_idx, actualObjTest, rep]));
            result_matrix = [func.tuningTime, -1, actualObjTest, -1];
            csvwrite(options.valall_filename, result_matrix);
        end
    end

    workspace_filename = strcat([options.workspace_filenameprefix, '_m1_', '.mat']);
    if options.saving>0
        bout(sprintf(['Saving final workspace to ' workspace_filename '\n']));
        save(workspace_filename);
    end
end
function valdata = outputCurrentStatisticsAndRunFiles(workspace_savedir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options)
global allParamStrings
if numRun < options.numRunsToSaveDetails
    %=== Write output files.
    
    csvwrite(strcat([workspace_savedir, 'runs_and_results.csv']), runs_and_results_matrix(rundata));
    csvwrite(strcat([workspace_savedir, 'uniq_configurations.csv']), [(1:size(ThetaUniqSoFar,1))', ThetaUniqSoFar]);
    
    %=== Write special output files on iterative deepening schedule.
    if iteration == valdata.next_iteration_to_output
        bout(strcat(['Outputting detailed information into files at iteration ', num2str(iteration), '\n']));
        csvwrite(strcat([workspace_savedir, 'uniq_configurations-it', num2str(iteration), '.csv']), [(1:size(ThetaUniqSoFar,1))', ThetaUniqSoFar]);
        csvwrite(strcat([workspace_savedir, 'runs_and_results-it', num2str(iteration), '.csv']), runs_and_results_matrix(rundata));
    
        %=== Output allParamStrings.
        param_out_fid = fopen(strcat([workspace_savedir, 'paramstrings-it', num2str(iteration), '.txt']),'w');
        for i=1:length(allParamStrings)
            fprintf(param_out_fid,  [num2str(i), ': ', allParamStrings{i}, '\n']);
        end
        fclose(param_out_fid);
            valdata.next_iteration_to_output = valdata.next_iteration_to_output*2;
%        valdata.next_iteration_to_output = valdata.next_iteration_to_output+1;

        %=== Output profiler info
        if ~isdeployed && options.profile
            if options.profile == 1
                proftype = 'cpu';
            elseif options.profile == 2
                proftype = 'real';
            end
            profsave( profile('INFO'), parsePath(['prof-', proftype, '-it', num2str(iteration)], workspace_savedir) );
        end
    end
end

function out = runs_and_results_matrix(rundata)
out = [(1:length(rundata.y))', ...
       rundata.used_theta_idxs, ...
       rundata.used_instance_idxs, ...
       rundata.y, ...
       rundata.cens, ...
       rundata.used_captimes, ...
       rundata.usedSeeds, ...
       rundata.runtimes, ...
       rundata.runlengths, ...
       rundata.solveds, ...
       rundata.best_sols, ...
       rundata.iterations, ...
       rundata.time_until_here];
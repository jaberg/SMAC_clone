function outputNewBest(algoRuntime, track_min_mean, track_min_std, inc_theta_idx, alTunerTime, iterationTime, x, numruns_theta_idx, totalRuns, iteration)
%=== Here, we are counting BOTH algoRuntime and alTunerTime as the total
%runtime. We separately output alTunerTime.
global detailed_traj_fid;
global incumbent_matrix;
bout(sprintf('Incumbent at iteration %d: %d with %f +/- %f and %d runs. Iteration time: %f, total overhead time: %f, total raw algo runtime: %f, total runs: %d\n', [iteration, inc_theta_idx, track_min_mean, track_min_std, numruns_theta_idx, iterationTime, alTunerTime, algoRuntime, totalRuns]));
tout(sprintf('%f, %f, %f, %d, %f', [algoRuntime+alTunerTime, track_min_mean, track_min_std, inc_theta_idx, alTunerTime]));
str = strcat([', ', num2str(numruns_theta_idx), ', ', num2str(totalRuns), ', ' num2str(iteration)]);
fprintf(detailed_traj_fid, str);
tout(sprintf(', %s', x));
tout(sprintf('\n'));

% Keep track of historic incumbents for offline evaluation.
incumbent_matrix = [incumbent_matrix; [algoRuntime+alTunerTime, track_min_mean, inc_theta_idx, alTunerTime]];
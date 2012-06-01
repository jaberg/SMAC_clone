function [reading, censored, runtime, dummy_runlength, solved, dummy_bestsol] = censoredReading(func, funcHandle, Theta_idx, instance_numbers, seeds, censorLimits)
global ThetaUniqSoFar;
global TestTheta;
global resfid;
global runTimeForRunningAlgo;

reading = -ones(length(Theta_idx),1);
censored = -ones(length(Theta_idx),1);
for i=1:length(Theta_idx)
    theta_idx = Theta_idx(i);
    if theta_idx < 0
        theta = TestTheta(-theta_idx,:);
    else
        theta = ThetaUniqSoFar(theta_idx,:);
    end
    theta = config_back_transform(theta, func);
    
    for j=1:func.dim
        if ismember(j, func.cat)
            theta(j) = str2double(func.all_values{j}{theta(j)});
        end
    end
    uncensoredReading = funcHandle(theta, instance_numbers(i), seeds(i), censorLimits(i));
    uncensoredReading = uncensoredReading;% + observationNoise*randn;
    if uncensoredReading < censorLimits(i)
        reading(i) = uncensoredReading;
        censored(i) = 0;
    else
        reading(i) = censorLimits(i);
        censored(i) = 1;
    end
    runTimeForRunningAlgo = runTimeForRunningAlgo + reading(i);
    fprintf(resfid, '%g, %d, %d, %d, %d', [reading(i), censored(i), theta_idx, instance_numbers(i), seeds(i)]);
    
    for j=1:size(theta,2)
        fprintf(resfid, ', %g', theta);
    end
    fprintf(resfid, '\n');
end
runtime = reading;
dummy_runlength = zeros(length(reading), 1);
solved = 1-censored;
dummy_bestsol = zeros(length(reading), 1);
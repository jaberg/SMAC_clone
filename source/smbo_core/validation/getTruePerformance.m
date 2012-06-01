%=== Evaluate true performance of parameters on instances.
function [actualObjTest, yAllTestAsVectorNoTrafo, trueMatrixNoTrafo, censAllTest] = getTruePerformance(func, dev_theta_idxs, instanceIdxToFill)
for i=1:length(instanceIdxToFill)
    seeds(i,:) = func.test_seeds(i);%instanceIdxToFill(i), 1:rep);
end
seeds = seeds(:);

dev_theta_idxs = dev_theta_idxs(:);
%=== First finish all runs for one configuration, then go to the next (same as SPO).
ThetaMatrixAsVector = repmat(dev_theta_idxs', [size(instanceIdxToFill,1)],1);
ThetaMatrixAsVector = ThetaMatrixAsVector(:);
instSeedsMatrixAsVector = repmat(instanceIdxToFill, [size(dev_theta_idxs,1), 1]);
seedsAsVector = repmat(seeds, [size(dev_theta_idxs,1), 1]);

tic;
bout(sprintf(strcat(['Evaluating function for every entry of the ', num2str(size(dev_theta_idxs,1)), ' by ', num2str(size(instanceIdxToFill,1)), ' matrix ...'])));

[yAllTestAsVectorNoTrafo, censAllTest] = func.testFuncHandle(ThetaMatrixAsVector, instSeedsMatrixAsVector, seedsAsVector, func.cutoff * ones(length(instSeedsMatrixAsVector),1));

if func.external
    yAllTestAsVectorNoTrafo = max(yAllTestAsVectorNoTrafo,0.005);
end

trueMatrixNoTrafo = reshape(yAllTestAsVectorNoTrafo', [size(instanceIdxToFill,1),size(dev_theta_idxs,1)])';
actualObjTest = combineRunObjectives(func.overallobj, trueMatrixNoTrafo, func.cutoff);

validationTimeForSingleModels = toc
bout(sprintf(strcat(['Evaluating function for every entry of the ', num2str(size(dev_theta_idxs,1)), ' by ', num2str(size(instanceIdxToFill,1)), ' matrix took ', num2str(validationTimeForSingleModels), ' seconds.'])));
clear ThetaMatrixAsVector instSeedsMatrixAsVector
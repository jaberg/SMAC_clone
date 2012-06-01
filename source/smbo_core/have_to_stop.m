function stopflag = have_to_stop(alTunerTime, runTime, func, used_instance_idxs, options, iteration)
stopflag = ((alTunerTime + sum(runTime) > func.tuningTime) || (alTunerTime + sum(runTime) > options.runtimeLimit) || (size(used_instance_idxs,1) >= options.totalNumRunLimit)) || (iteration >= options.numIterations);

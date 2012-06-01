function [incumbent_theta_idx, bestconflist, rundata, ThetaUniqSoFar] = getInitialData(func, options, numRun)
rundata = []; % forget anything from previous runs etc.
rundata.kappa_max =  func.cutoff;
rundata.updatedRunIdxs = [];
rundata.numNewRunsSinceLastBuild = 0;
iteration = 0;
global ThetaUniqSoFar;
global allParamStrings;

if isfield(options, 'initial_datafile') || isfield(options, 'ssa_configfile') || isfield(options, 'initialDataFilePrefix') || isfield(options, 'lhdSize')
    if isfield(options, 'initial_datafile')
        randomStar = 0;
        if strfind( options.initial_datafile, '.mat' )
            initial_datafile = options.initial_datafile;
            randomStar = 1;
        else
            initial_datafile = strcat([func.outdirScen, '/', options.initial_datafile, '-numRun', num2str(numRun), '.mat']);
        end
        load(initial_datafile, 'all_features_for_training_instances', 'rundata', 'alTunerTime', 'ThetaUniqSoFar', 'bestconflist', 'incumbent_theta_idx');
        rundata_loaded = rundata;
        rundata = []; % forget anything from previous runs etc.
        rundata.kappa_max =  func.cutoff;

        rundata.used_theta_idxs = rundata_loaded.used_theta_idxs;
        rundata.used_instance_idxs = rundata_loaded.used_instance_idxs;
        rundata.y = rundata_loaded.y;
        rundata.cens = rundata_loaded.cens;
        rundata.used_captimes = rundata_loaded.used_captimes;
        rundata.usedSeeds = rundata_loaded.usedSeeds;

        rundata.runtimes = rundata_loaded.y;
        rundata.runlengths = -ones(length(rundata_loaded.y),1);
        rundata.solveds = -ones(length(rundata_loaded.y),1);
        rundata.best_sols = -ones(length(rundata_loaded.y),1);
        rundata.iterations = zeros(length(rundata_loaded.y),1);
        rundata.time_until_here = zeros(length(rundata_loaded.y),1);
        rundata.runTime = zeros( max(options.totalNumRunLimit, 1),1 );
        
        %=== Save data in our new standard format.
        if randomStar
            initial_datadir = strcat([func.outdir, 'RandomStar-', num2str(length(rundata.y)), '-numRun', num2str(numRun)]);
        else
            initial_datadir = strcat([func.outdir, '-lhdSize', num2str(length(rundata.y)), '-numRun', num2str(numRun)]);
        end
        
        valdata.next_iteration_to_output = 0;
        outputCurrentStatisticsAndRunFiles(initial_datadir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options)

    elseif isfield(options, 'ssa_configfile')
        if isfield(options, 'ssa_resultfile')
            drop_first = 0;
            if isfield(options, 'drop_first_config')
                drop_first = options.drop_first_config;
            end
            ThetaUniqSoFar = read_param_configs(func, options.ssa_configfile, 1, drop_first);
            data = csvread(options.ssa_resultfile, 0, 1+drop_first);
            data = max(data, 0.005);
            
            %=== Make sure that the instances used in the result file are
            %=== the one training instances of func, and that the order is
            %=== consistent.
%            instance_names = textread(options.ssa_resultfile,'%s%*[^\n]', 'bufsize', 10000);
            instance_names = textread(options.ssa_resultfile,'%[^,]%*[^\n]', 'bufsize', 10000);
            
            numTrain = func.numTrainingInstances; % 5;
            map_func_inst_id_to_id_in_file = -ones(numTrain,1);
            for i=1:numTrain
                inst_name = func.instance_filenames{i};
                for j=1:length(instance_names)
                    if strcmp(inst_name, instance_names{j})
                        map_func_inst_id_to_id_in_file(i) = j;
                        break;
                    end
                end
                if map_func_inst_id_to_id_in_file(i) == -1
                    errstr = strcat(['Training instance with # ', num2str(i), ' does not occur in input result file.']);
                    error(errstr);
                end
            end
            
            data = data(map_func_inst_id_to_id_in_file, :); % align instances with the training instances.
            
            y = data(:); % first config, all instances; then 2nd config; etc
            cens = (y > func.cutoff);
            y(find(cens)) = func.cutoff;
            
            used_instance_idxs = repmat((1:numTrain)', [1, size(data,2)]);
            used_instance_idxs = used_instance_idxs(:);

            used_theta_idxs = repmat((1:size(data,2)), [size(data,1),1]);
            used_theta_idxs = used_theta_idxs(:);
            
        	rundata = []; % forget anything from previous runs etc.
            rundata.kappa_max =  func.cutoff;

            rundata.used_theta_idxs = used_theta_idxs;
            rundata.used_instance_idxs = used_instance_idxs;
            rundata.y = y;
            rundata.cens = cens;
            rundata.used_captimes = rundata.kappa_max * ones(length(y),1);
            rundata.usedSeeds = used_instance_idxs + 1000000; % seeds were not recorded

            rundata.runtimes = y;
            rundata.runlengths = -ones(length(y),1);
            rundata.solveds = -ones(length(y),1);
            rundata.best_sols = -ones(length(y),1);
            rundata.iterations = zeros(length(y),1);
            rundata.time_until_here = zeros(length(y),1);
            rundata.runTime = zeros( max(options.totalNumRunLimit, 1),1 );

            %=== Save data in our new standard format.
            ssa_datadir = strcat([func.outdir, '-ssa', num2str(length(rundata.y)), '-numRun', num2str(numRun)]);
            valdata.next_iteration_to_output = 0;
            outputCurrentStatisticsAndRunFiles(ssa_datadir, ThetaUniqSoFar, rundata, valdata, iteration, numRun, options);

            rundata = subsampleRundata(rundata, 10000);

        else
            error('ssa_configfile only goes together with ssa_resultfile, but the latter is not specified')
        end
    else
        if isfield(options, 'lhdSize')
            initial_datadir = strcat([func.outdir, '-lhdSize', num2str(options.lhdSize), '-numRun', num2str(numRun)]);
        elseif isfield(options, 'initialDataFilePrefix')
            initial_datadir = options.initialDataFilePrefix;
        else error('Need either lhdSize or initialDataFilePrefix');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % START FROM A FILE WITH DATA FROM A PREVIOUS RUN / FROM AN LHD.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        run_result_file = parsePath('runs_and_results.csv', initial_datadir);
        uniq_conf_file = parsePath('uniq_configurations.csv', initial_datadir);

        bout(sprintf(['Reading existing data from files ', run_result_file, ' and ', uniq_conf_file, '\n']));

        tmp = csvread(uniq_conf_file);
        ThetaUniqSoFar = tmp(:,2:end);

        data = csvread(run_result_file);

        rundata.used_theta_idxs = data(:,2);
        rundata.used_instance_idxs = data(:,3);
        rundata.y = data(:,4);
        rundata.cens = data(:,5);
        rundata.used_captimes = data(:,6);
        rundata.usedSeeds = data(:,7);
        rundata.runtimes = data(:,8);
        rundata.runlengths = data(:,9);
        rundata.solveds = data(:,10);
        rundata.best_sols = data(:,11);
        rundata.iterations = data(:,12);
        rundata.time_until_here = data(:,13);
    end

    rundata.runTime = zeros( max(options.totalNumRunLimit, 1),1 );
    rundata.runTime(1) = rundata.time_until_here(end);
    
    iteration = rundata.iterations(end);
    alTunerTime = max(rundata.time_until_here);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At this point, we have read in rundata and ThetaUniqSoFar by one
    % of various methods; now, use that to initialize the rest of the
    % datastructures.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if options.just_valid == 0
        %=== Construct the parameter strings.
        for theta_idx=1:size(ThetaUniqSoFar,1)
            if 0 % double-check
                idx = update_if_new_param_config(func, ThetaUniqSoFar(theta_idx, :));
                assert(idx == theta_idx); % the meaning of a configuration's index must remain the same!
            else
                 allParamStrings{theta_idx} = alphabeticalParameterString(func, ThetaUniqSoFar(theta_idx,:));
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Determine the incumbent: out of the ones with a maximal number of 
    % runs, it is the one with the best performance 
    % (censored runs are counted as censored at kappa_max).
    % I'll break ties to favour the one with the lowest index.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    idxs_max_occurence = [1];
    max_occurence = length(find(rundata.used_theta_idxs == 1));
    
    for theta_idx = 2:size(ThetaUniqSoFar,1)
        all_occurrences = find(rundata.used_theta_idxs == theta_idx);
        if ~isempty(intersect( find(rundata.cens(all_occurrences) == 1), find(rundata.y(all_occurrences) < rundata.kappa_max) ) )
            %if this theta has a run capped below kappa_max, it can't be the incumbent so we don't even consider it.
            all_occurrences = 0;
        end
        num_this_occurence = length(all_occurrences);
        
        if num_this_occurence >= max_occurence
            if num_this_occurence > max_occurence
                max_occurence = num_this_occurence;
                idxs_max_occurence = [];
            end
            idxs_max_occurence = [idxs_max_occurence, theta_idx];
        end
    end
    
    incumbent_theta_idx = idxs_max_occurence(1);
    mincost = empirical_cost_for_idx(rundata, options, incumbent_theta_idx);
    for i = 2:length(idxs_max_occurence)
        cost = empirical_cost_for_idx(rundata, options, idxs_max_occurence(i));
        if cost < mincost
            mincost = cost;
            incumbent_theta_idx = idxs_max_occurence(i);
        end
    end

    bestconflist = -ones( max(options.totalNumRunLimit, 1),1 );
    bestconflist(1:end) = incumbent_theta_idx;
    
    %=== Assert invariant: the incumbent does not have any runs that were
    %=== censored below kappa_max.
    inc_idxs = find(rundata.used_theta_idxs == incumbent_theta_idx);
    if ~isempty(intersect( find(rundata.cens(inc_idxs)==1), find(rundata.y(inc_idxs) < rundata.kappa_max) ))
        error('Incumbent can not have runs censored below kappa_max! Parsing problem with initial data files?');
    end
    bout(sprintf(['Incumbent from those files is config with index ', num2str(incumbent_theta_idx), ' and empirical cost ', num2str(mincost), ' based on ', num2str(max_occurence),' runs.\n']));
    if options.logModel == 1 || options.logModel == 3
        mincost = log10(mincost);
    end
    outputNewBest(sum(rundata.runTime), mincost, -1, incumbent_theta_idx, alTunerTime, 0, alphabeticalParameterString(func, ThetaUniqSoFar(incumbent_theta_idx,:)), max_occurence, length(rundata.used_theta_idxs), iteration);

else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % INITIALIZE WITH RUNS WE DO HERE.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ThetaUniqSoFar = [];
    rundata.used_theta_idxs = [];
    rundata.used_instance_idxs = [];
    rundata.y = [];
    rundata.runtimes = [];
    rundata.runlengths = [];
    rundata.best_sols = [];
    rundata.solveds = [];
    rundata.cens = [];
    rundata.used_captimes = [];
    rundata.usedSeeds = [];
    rundata.iterations = [];
    rundata.time_until_here = [];
    
    rundata.runTime = zeros( max(options.totalNumRunLimit, 1),1 );
    bestconflist = -ones( max(options.totalNumRunLimit, 1),1 );

    N = func.numTrainingInstances;
    if options.nInit > 0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % START THE OPTIMIZATION WITH AN LHD.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        s = rand('twister');
        lhd_seed = ceil(100000 * rand);
        LHD_design = spread_hybrid_lhsamp(lhd_seed, func.dim+1, options.nInit, [func.cat, func.dim+1], func.cont, [func.num_values, N], [func.param_bounds; 0, 0], options.initType, 1);
%         LHD_design = spread_hybrid_lhsamp(lhd_seed, func.dim, options.nInit, func.cat, func.cont, func.num_values, func.param_bounds, options.initType, 1);
        rand('twister', s);
        LHD_design = [func.default_values', ceil(rand*N); LHD_design];
        torun = LHD_design;
        
        configs = LHD_design(:,1:end-1);
%         configs = unique(configs, 'rows');
        pi_idxs = LHD_design(:,end);
        N = size(configs,1);
        for i=1:N
            theta_new_idxs(i) = update_if_new_param_config(func, configs(i,:));
            [dummy_pi_idx, dummy_captime, seeds(i)] = selectInstCaptimeSeedForIncStratified(theta_new_idxs(i), rundata, func);
        end

        if options.adaptive_capping
            numUncens = 0;
            captime = 0.01;
            while numUncens < N/2
                for i=1:N
                    rundata = dorun(func, theta_new_idxs(i), pi_idxs(i), captime, seeds(i), iteration, rundata);
                end
                numUncens = length(find(rundata.cens==0));
                if captime >= options.kappa_max;
                    break;
                end
                captime = captime * 2;
                captime = min(captime, options.kappa_max+1e-6);
            end
        else
            for i=1:N
                rundata = dorun(func, theta_new_idxs(i), pi_idxs(i), inf, seeds(i), iteration, rundata);
            end
        end
        uncens_idx = find(rundata.cens==0);
        [tmp, tmp_idx] = min(rundata.y(uncens_idx));
        incumbent_theta_idx = uncens_idx(tmp_idx);
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % START THE OPTIMIZATION WITH A SINGLE RUN OF THE DEFAULT.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%        torun = [theta_def, ceil(N*rand)];
        torun = func.default_values';
        theta_def = torun(1,:);
        incumbent_theta_idx = update_if_new_param_config(func,theta_def);
		bout(sprintf('Doing one run for the default ...\n'));
        minRawAlgoTime = 0.001;
        [incumbent_theta_idx, bestconflist, rundata] = compareChallengersAgainstIncumbent(torun, incumbent_theta_idx, 'nomodel', func, rundata, iteration, minRawAlgoTime, options, 0, 0, bestconflist);
    end    
end


function cost = empirical_cost_for_idx(rundata, options, theta_idx)
single_costs = rundata.y(rundata.used_theta_idxs == theta_idx);
single_censored_idx = find(rundata.cens(rundata.used_theta_idxs == theta_idx));
single_costs(single_censored_idx) = rundata.kappa_max + 0.01;
single_costs = single_costs(:)';
cost = combineRunObjectives(options.overallobj, single_costs, rundata.kappa_max);

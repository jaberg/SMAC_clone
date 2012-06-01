function model = readRunsAndBuildModel( scenario_file, config_file, initial_datadir, varargin )
    func = process_func_arguments('scenario_file', scenario_file, 'config_file', config_file);
    func = parse_inst_files(func, 0, false);
    
    options = parse_smbo_arguments(varargin{:});
    options.kappa_max = func.cutoff;
    options = set_options(options);    
    
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
    y_model = data(:,4);
    cens_model = data(:,5);
    
    %=== Make sure that runtime data is positive and solution quality not too extreme.
    if options.logModel == 1 || options.logModel == 3
        %=== Zeros would break a log model. Replace them by half the
        %=== minimal positive value we have observed (but at most 0.005)
        assert(all(y_model>-1e-6), strcat(['When using a log model, all y values have to be positive, but the actual min y value is ', min(y_model)]));
        if sum(y_model<=0) > 0
            if sum(y_model>0) > 0
                min_value = min(0.005, min(y_model(y_model>0))/2);
            else
                min_value = 0.005;
            end
            y_model(y_model<=0) = repmat(min_value, 1, sum(y_model<=0));
        end
    end
    if any(y_model>1e9)
        warning('Extreme response values (>10^9). That might break the numerical precision of SMAC.');
    end

    switch options.adaptive_capping
        case {0,-1}
            %=== For now, using 10*cutoff, and learning model without censoring.
            y_model(find(cens_model)) = options.cutoff_penalty_factor .* max(y_model(find(cens_model)), func.cutoff); % max is for special case of SAPS-QWH, normally just func.cutoff
            %=== TODO: use the one below instead? (need stat. experiments)
            % y_model(find(rundata.cens)) = options.cutoff_penalty_factor .* func.cutoff;
            cens_model = zeros(length(cens_model),1);
        case -2
            cens_model = zeros(length(cens_model),1);
        case 1
        otherwise
            error 'capping only has allowed values -2 (count a cap at kappa_i as kappa_i), -1 (count all caps as 10*kappa_max), 0 (always kappa_i=kappa_max; count as 10*kappa_max), and 1 (capped model).'
    end
    
    model = learnMarginalModel([rundata.used_theta_idxs, rundata.used_instance_idxs], ThetaUniqSoFar, func.features, y_model, cens_model, func.cat, func.all_values, [], cell(1, size(func.features, 2)), func.cond_params_idxs, func.parent_param_idxs, func.ok_parent_value_idxs, 0, options, func.param_names);
end


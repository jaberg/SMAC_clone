function valdata = getValdata(func, options, numRun)
rand('twister',numRun+1);
randn('state',numRun+1);

DEV_test_design = [];
valActualObjTest = [];
valTrueMatrixNoTrafo = [];

valdata.numRun = numRun;
valdata.numRunsToSaveDetails = options.numRunsToSaveDetails;

if options.valid || options.just_valid
    error('Error: Not working.'); %TODO: Eventually decouple this file from SMBO
    allDEV_test_design = [];
    allvalTrueMatrixNoTrafo = [];
    allvalActualObjTest = [];
    dev_theta_idxs = [];

    dev_matrix_file_names = {strcat([func.outdirScen, options.overallobj, '_dev_and_val_matrix.csv']), strcat([func.outdirScen, options.overallobj, '_good_dev_and_val_matrix.csv'])};
    dev_val_file_names = {strcat([func.outdirScen, options.overallobj, '_dev_and_val.csv']), strcat([func.outdirScen, options.overallobj, '_good_dev_and_val.csv'])};
    for part=1:2
        dev_matrix_file_name = dev_matrix_file_names{part};
        dev_val_file_name = dev_val_file_names{part};
        have_to_run = 0;

        maxLen = 100;
        if exist(dev_val_file_name, 'file')
            data = csvread(dev_val_file_name);
            len = min(maxLen, size(data,1));
            valActualObjTest = data(1:len, end);
            DEV_test_design = data(1:len, 1:end-1);
% To not use the good configurations:                
%                 if part == 2
%                     valActualObjTest = [];
%                     DEV_test_design = [];
%                 end
        else
            have_to_run = 1;
        end

        if options.matrix_validation > 0
            if exist(dev_matrix_file_name, 'file')
                len = min(maxLen, size(data,1));
                data = csvread(dev_matrix_file_name);
                idx = find(data(1,:) == -1);

                DEV_test_design2 = data(1:len, 1:idx-1);
                DEV_test_design2 = config_transform(DEV_test_design2, func);

                valTrueMatrixNoTrafo = data(1:len, idx+1:end);
                assertVectorEq(DEV_test_design, DEV_test_design2);
            else
                have_to_run = 1;
            end
        end

        %            have_to_run = 1;
        if have_to_run
            s=rand('twister');
            bout(sprintf('PREPARING FOR LATER VALIDATION ...\nGenerating LHD...'));

            % Could use different method to determine DEV_test_design, e.g.
            % configurations in a saved file.

            if part == 1
                s1 = rand('twister');
                s2 = randn('state');
                rand('state',1234); randn('state',1234); % same as SPO
                lhdLength = 100; %5
                if strcmp(func.name, 'levy_1d_rnd') || strcmp(func.name, 'levy_1d_nornd') || strcmp(func.name, 'levy_1d_rnd_add_noise') || strcmp(func.name, 'levy_1d_rnd_nonstat')
                    lhdLength = 1000;
                end
                %DEV_test_design = spotlatinhypercube(lhdLength, func.dim, func.param_bounds(:,1), func.param_bounds(:,2));
                DEV_test_design = spread_hybrid_lhsamp(numRun+1001, func.dim, lhdLength, func.cat, func.cont, func.num_values, func.param_bounds, 'random_lhd', 1);
                rand('twister',s1);
                randn('state',s2);

                %            DEV_test_design = spread_hybrid_lhsamp(seed, func.dim, 100, func.cat, func.cont, func.num_values, func.param_bounds, 'ihs', 1); % was: random
                bout(sprintf(['LHD generated. Now evaluating function ...\n']));
            else
                good_filename = strcat([func.outdirScen, 'good-params.csv']);
                if exist(good_filename, 'file')
                    DEV_test_design = read_param_configs(func, good_filename);
                else
                    DEV_test_design = [];
                end
            end
            rand('twister', s);

            %             DEV_test_design = zeros(2401, 4); for i=0:2401-1, DEV_test_design(i+1,:) = [floor(i/(7^3)), floor(mod(i, 7^3)/(7^2)), floor(mod(i, 7^2)/(7^1)), floor(mod(i, 7^1)/(7^0))]+1; end

            start_this_dev_theta_idxs = length(dev_theta_idxs)+1;
            
            for i=1:size(DEV_test_design, 1)
                dev_theta_idxs(end+1,1) = update_test_if_new_param_config(func,DEV_test_design(i,:));
            end

            %             for i=1:length(ThetaUniqSoFar)
            %                 outputNewBest(0, 0, 0, dev_theta_idxs(i), 0, allParamStrings{dev_theta_idxs(i)}, 0, 0, 0);
            %             end
            %             return

            %[valActualObjTest, valYAllTestAsVectorNoTrafo, valTrueMatrixNoTrafo, valCensAllTest] = getTruePerformance(func, dev_theta_idxs, (1:N)');
            rep = 100;
            if strfind(func.name, 'SAPS-QWH')
                rep = 1000;
            end
            if ~func.external
                if (strcmp(func.name, 'levy_1d_rnd') || strcmp(func.name, 'levy_1d_nornd') || strcmp(func.name, 'levy_1d_rnd_add_noise') || strcmp(func.name, 'levy_1d_rnd_nonstat')) && part == 1
                    DEV_test_design = config_transform([-15:0.01:10]', func);
                    dev_theta_idxs = [];
                    for i=1:size(DEV_test_design, 1)
                        dev_theta_idxs(end+1,1) = update_test_if_new_param_config(func,DEV_test_design(i,:));
                    end
                    %if strcmp(func.name, 'levy_1d_nornd')
                    valActualObjTest = levy_1d_nornd(config_back_transform(DEV_test_design, func), 0, 1);
                    %else
                    %    valActualObjTest = levy_1d_rnd(config_back_transform(DEV_test_design, func), 0, 1);
                    %end
                    valYAllTestAsVectorNoTrafo = [];
                    valTrueMatrixNoTrafo = [];
                    valCensAllTest = [];
                else
                    rep = 1;
                    [valActualObjTest, valYAllTestAsVectorNoTrafo, valTrueMatrixNoTrafo] = getTruePerformance(func, dev_theta_idxs(start_this_dev_theta_idxs:end), (1:func.numTrainingInstances)');
                end
            else
                if func.numTrainingInstances == 1
                    all_inst_repl = repmat((1:func.numTrainingInstances)', [rep,1]);
                else
                    all_inst_repl = (1:func.numTrainingInstances)';
                end
                %                all_inst_repl = all_inst_repl(1:min(length(all_inst_repl), 1000));
                if isempty(DEV_test_design)
                    valActualObjTest = [];
                    valTrueMatrixNoTrafo = [];
                else
                    [valActualObjTest, valYAllTestAsVectorNoTrafo, valTrueMatrixNoTrafo] = getTruePerformance(func, dev_theta_idxs(start_this_dev_theta_idxs:end), all_inst_repl);
                end
            end
            %             all_inst_repl = repmat((1:N)', [100,1]);
            %             s1 = rand('twister'); % b/c we change the seed inside when randomly picking seeds for the target algorithm.
            %             [valActualObjTest, valYAllTestAsVectorNoTrafo, valTrueMatrixNoTrafo, valCensAllTest] = getTruePerformance(func, dev_theta_idxs, all_inst_repl);
            %             getTruePerformance(func, conf_id, (1:func.numTestInstances)');
            %             rand('twister',s1);

            csvwrite(dev_val_file_name, [DEV_test_design, valActualObjTest]);
            csvwrite(dev_matrix_file_name, [DEV_test_design, -ones(size(DEV_test_design,1),1), valTrueMatrixNoTrafo]);
        else
            for i=1:size(DEV_test_design, 1)
                dev_theta_idxs(end+1,1) = update_test_if_new_param_config(func,DEV_test_design(i,:));
            end
        end
        allDEV_test_design = [allDEV_test_design; DEV_test_design];
        allvalTrueMatrixNoTrafo = [allvalTrueMatrixNoTrafo; valTrueMatrixNoTrafo];
        allvalActualObjTest = [allvalActualObjTest; valActualObjTest];
    end
    DEV_test_design = allDEV_test_design;
    valTrueMatrixNoTrafo = allvalTrueMatrixNoTrafo;
    valActualObjTest = allvalActualObjTest;

    %=== Assert that continuous parameters are normalized.
    assert(all(all(DEV_test_design(:, func.cont) > -1e-6)));
    assert(all(all(DEV_test_design(:, func.cont) < 1 + 1e-6)));

    valdata.DEV_test_design = DEV_test_design;
    valdata.valTrueMatrixNoTrafo = valTrueMatrixNoTrafo;

    valdata.dev_theta_idxs = dev_theta_idxs;
    valdata.valActualObjTest = valActualObjTest;
end
valdata.next_iteration_to_output = 1;

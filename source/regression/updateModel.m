function model = updateModel(model, newDataIdxs, ThetaUniqSoFar, ynew, censnew, isclean)    
    if ~isclean
        if model.options.logModel == 1 || model.options.logModel == 3
            ynew = log10(ynew);
        end
		ThetaUniqSoFar = ThetaUniqSoFar(:, model.kept_Theta_columns);
    end

    ThetaUniqSoFar = ThetaUniqSoFar(newDataIdxs(:,1), :);
    all_instance_features = model.pcaed_instance_features(newDataIdxs(:,2), :);
    Xnew = [ThetaUniqSoFar, all_instance_features];
    
    switch model.type
        case {'javarf', 'fastrf'}
			if strcmp(model.type, 'javarf')
	            importstr = 'ca.ubc.cs.beta.models.rf.*';
			else
				importstr = 'ca.ubc.cs.beta.models.fastrf.*';
            end
            import(importstr);

            censored_idxs = find(censnew);
            if ~isempty(censored_idxs)
                maxY = max([model.y; ynew]);
                if model.options.logModel == 1
                    maxY = 10.^maxY;
                end
                kappa = model.options.kappa_max;
                if model.options.logModel == 3
                    kappa = log10(kappa);
                end
                valueForAllCens = model.options.cutoff_penalty_factor * kappa;
                valueForAllCens = max(valueForAllCens, maxY);
            
                if true %~isdeployed % running from matlab so no access to javabuilder stuff. 
                    result = RandomForest.collectData(model.T, Xnew);
                    y_pred_all = result(1);
                    cens_pred_all = result(2);
                    weights_all = result(3);
                    if ~iscell(y_pred_all) 
                        y_pred_all = mat2cell(y_pred_all, ones(size(y_pred_all, 1), 1), size(y_pred_all, 2));
                        cens_pred_all = mat2cell(cens_pred_all, ones(size(cens_pred_all, 1), 1), size(cens_pred_all, 2));
                        weights_all = mat2cell(weights_all, ones(size(weights_all, 1), 1), size(weights_all, 2));
                    end

                    for i=1:length(censored_idxs)
                        %== Fit distribution and sample above the censored value.
                        c_i = censored_idxs(i);

                        sample = double(fit_dist_and_sample(y_pred_all{i}, cens_pred_all{i}, weights_all{i}, 1, ynew(c_i), valueForAllCens));
                        assert(sample >= ynew(c_i), 'imputed data must be larger than the censored value');
                        ynew(c_i) = sample;
                    end
                    censnew = zeros(size(ynew));
                end
            else 
                valueForAllCens = inf;
            end
            RandomForest.update(model.T, Xnew, ynew, censnew, valueForAllCens, model.options.logModel);
            model.P = RandomForest.preprocessForest(model.T, model.pcaed_instance_features);
        otherwise
            error(['updateModel is not defined for model type ', model.type]);
    end
end
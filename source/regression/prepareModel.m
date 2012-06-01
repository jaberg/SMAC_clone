function [model, nlml, dnlml] = prepareModel(model, invKmm)
assert(all(isfinite(model.y)));

switch model.type
    case {'rf', 'javarf', 'fastrf'}
    otherwise
        if isempty(strfind(model.type, 'GP'))
            error 'need to implement model for this modelType';
        end
end
    
if model.prepared
    nlml = 0;
    dnlml = 0;
    warning 'Model already prepared.'
%    return
end

switch model.type
    case {'rf', 'javarf', 'fastrf'}
    try
        N = length(model.y);
        M = model.options.nSub;
        
        if model.options.orig_rf
            r = ceil(N.*rand(N,M));
        else
            r = repmat((1:N)',[1,M]); %new type of RF, where each tree has the same data. 
        end
                
        %=== Unpack params.
        tuning_params = (model.params - model.options.paramsLowerBound) ./ (model.options.paramsUpperBound - model.options.paramsLowerBound);
        ratioFeatures = tuning_params(1);
        Splitmin = max(1, ceil(tuning_params(2)*model.options.splitMinMax-0.5));
        Splitmincens = max(1, ceil(tuning_params(3)*model.options.splitMinMax-0.5));

		isjavarf = strcmp(model.type, 'javarf') || strcmp(model.type, 'fastrf');
        if strcmp(model.type, 'javarf')
            importstr = 'ca.ubc.cs.beta.models.rf.*';
        elseif strcmp(model.type, 'fastrf')
            importstr = 'ca.ubc.cs.beta.models.fastrf.*';
        else
            importstr = '';
        end
        import(importstr);

		if isjavarf
		    javaparams = RegtreeBuildParams;
		    javaparams.ratioFeatures = ratioFeatures;
		    javaparams.catDomainSizes = model.cat_domain_sizes;
		    javaparams.kappa = model.options.kappa_max;
		    javaparams.logModel = model.options.logModel;

		    if ~isempty(model.cond) && ~model.options.ignore_conditionals
		        intCondParentVals = model.condParentVals;
		        for i=1:length(intCondParentVals)
		            intCondParentVals{i} = int32(intCondParentVals{i});
		        end
		        javaparams.conditionalsFromMatlab(model.cond, model.condParent, intCondParentVals, size(model.X, 2));
		    end
		end
        
        ydata = cell(M, 1); % stores the response data used to build the rf.
        
        %=== start building rf
        hascens = any(model.cens);
        if hascens
            bout(sprintf('Model has censored data - using survival forest\n'));
            %=== Learn SF, and fill in censored data with sampled data, for each tree.

            %== Assign training points and learn trees.
			if isjavarf
            	model.S = RandomForest(M);
			end
            model.yHal = cell(M, 1);
            
            %== Learn SF.
            javaparams.splitMin = Splitmincens;
            javaparams.storeResponses = true;
            for m=1:M
                this_r = r(:,m);
				ysub = model.y(this_r);
                censsub = model.cens(this_r);
				model.yHal{m} = ysub;

				seed = ceil(rand*10000000);
				if isjavarf
                    javaparams.seed = seed;
                    if strcmp(model.type, 'javarf')
                        javaparams.X = model.X(this_r, :);
                        javaparams.y = ysub;
                        javaparams.cens = censsub;
                        model.S.Trees(m) = RegtreeFit.fit((1:N)-1, javaparams);
                    else
                        dataIdxs = model.Theta_inst_idxs(this_r, :) - 1; % matlab is 1-indexed
                        model.S.Trees(m) = RegtreeFit.fit(model.ThetaUniqSoFar, model.all_instance_features, dataIdxs, ysub, censsub, javaparams);
                    end
                    java.lang.System.gc;
				else
					Xsub = model.X(this_r, :);
                    model.module{m}.S = fh_simple_random_regtreefit_algoParams_instFeats_c(Xsub, ysub, censsub, Splitmincens, ratioFeatures, model.cat, model.catDomains, seed, model.options.kappa_max, model.options.logModel, model.options.overallobj);
				end
            end
            
            %== For each censored data point, fit parametric (Weibull)
            %distribution to set of data points in the set of leaves
            %consistent with data point (<splitMin data points in each leaf, 10 trees).
            %Then, sample once from that distribution for each occurrence of
            %that data point in r (fill in censored data differently each
            %time)
            
            censored_idxs = find(model.cens);
            lowerBoundForSamples = model.y(censored_idxs);
            maxY = max(model.y);
            
            if model.options.logModel == 1
               lowerBoundForSamples = 10.^lowerBoundForSamples;
               maxY = 10.^maxY;
            end
            
            kappa = model.options.kappa_max;
            if model.options.logModel == 3
                kappa = log10(kappa);
            end
            valueForAllCens = model.options.cutoff_penalty_factor * kappa;
            valueForAllCens = max(valueForAllCens, maxY);
            
            numOccurrence = zeros(M, 1);
            for i=1:length(censored_idxs)
                totalOccurrence = 0;
                for m=1:M
                    numOccurrence(m) = length(find(r(:,m) == censored_idxs(i)));
                    totalOccurrence = totalOccurrence + numOccurrence(m);
                end
                if totalOccurrence == 0
                    continue;
                end
            
                dataIdxs = model.Theta_inst_idxs(censored_idxs(i),:);
                Theta = model.ThetaUniqSoFar(dataIdxs(1),:);
                inst = model.all_instance_features(dataIdxs(2),:);
                if isjavarf && false %isdeployed % Currently suffers from MCR multiple instance issue so cannot be run on a cluster I believe.
                    %== Propagate all censored points down all trees, collect data in leaves.
                    result = cell(RandomForest.hallucinateData(model.S, [Theta, inst], numOccurrence, lowerBoundForSamples(i), valueForAllCens, model.options.logModel));
                    for m=1:M
                        if numOccurrence(m) ~= 0
                            samples = result(m);
                            model.yHal{m}(r(:,m) == censored_idxs(i)) = [samples{:}];
                        end
                    end
                else % if running from matlab or not using the java model
                    %== Propagate all censored points down all trees, collect data in leaves.
                    if isjavarf		        
                        result = RandomForest.collectData(model.S, [Theta, inst]);
                        y_pred_all = result(1);
                        cens_pred_all = result(2);
                        weights_all = result(3);
                    else % mex rf
                        y_pred_cell_of_cells = cell(M,1);
                        cens_pred_cell_of_cells = cell(M,1);
                        for m=1:M
                            [y_pred_cell_of_cells{m}, cens_pred_cell_of_cells{m}] = fh_simple_cens_one_treeval(model.module{m}.S, model.X(censored_idxs(i),:));
                        end
                        y_pred_all = [];
                        cens_pred_all = [];
                        weights_all = [];
                        for m=1:M
                            y_pred_all = [y_pred_all, y_pred_cell_of_cells{m}{:}];
                            cens_pred_all = [cens_pred_all, cens_pred_cell_of_cells{m}{:}];
                            weights_all = [weights_all, 1/length(y_pred_cell_of_cells{m}{:}) * ones(1,length(y_pred_cell_of_cells{m}{:}))];
                        end
                        y_pred_all(cens_pred_all==0) = y_pred_all(cens_pred_all==0)+1e-10;
                    end

                    %== Fit distribution and sample above the censored value.
                    samples = fit_dist_and_sample(y_pred_all, cens_pred_all, weights_all, totalOccurrence, lowerBoundForSamples(i), valueForAllCens);
                    assert(all(samples >= lowerBoundForSamples(i)), 'imputed data must be larger than the censored value');

                    if model.options.logModel == 1
                        samples = log10(samples);
                    end

                    %== Fill in hallucinated values.
                    sample_idx = 1;
                    for m=1:M
                        idxs = find(r(:,m)==censored_idxs(i));
                        model.yHal{m}(idxs) = samples(sample_idx:sample_idx+length(idxs)-1);
                        sample_idx = sample_idx + length(idxs);
                    end
                    assert(sample_idx == totalOccurrence+1);
                end
            end
			if isjavarf
	            clear model.S;
			else
				for m=1:M
					clear model.module{m}.S;
				end
			end

            %=== Assert that hallucination worked right.
            %=== Fit regression trees on uncensored + hallucinated data.
            for m=1:M              
                this_r = r(:,m);
                ysub = model.y(this_r);
                censsub = model.cens(this_r);
                cens_idx = find(censsub==1);
                uncens_idx = find(censsub==0);
                assert(all(model.yHal{m}(cens_idx) >= ysub(cens_idx)-1e-5), 'imputed data must be larger than the censored value');
                assert(all(model.yHal{m}(uncens_idx) == ysub(uncens_idx)));
            end
            ydata = model.yHal;
        else 
            bout(sprintf('Model has no censored data - using normal random forest\n'));
            %=== Just do "normal" RF.
            ydata = {};
            for m=1:M
                ydata{m} = model.y(r(:, m));
            end
        end
        
        %=== build the final uncensored tree using ydata
		if isjavarf
		    model.T = RandomForest(M);
		    javaparams.splitMin = Splitmin;
		    javaparams.storeResponses = model.options.storeDataInLeaves || (hascens && model.options.frac_for_refit ~= 0);
		end
        for m=1:M
            this_r = r(:,m);
            ysub = ydata{m};
            censsub = zeros(length(this_r),1);
			
			seed = ceil(rand*10000000);
			if isjavarf
		        javaparams.seed = seed;
                if strcmp(model.type, 'javarf')
                    javaparams.X = model.X(this_r, :);
                    javaparams.y = ysub;
                    javaparams.cens = censsub;
                    model.T.Trees(m) = RegtreeFit.fit((1:N)-1, javaparams);
                else %fastrf       
                    dataIdxs = model.Theta_inst_idxs(this_r, :) - 1; % matlab is 1-indexed
                    model.T.Trees(m) = RegtreeFit.fit(model.ThetaUniqSoFar, model.all_instance_features, dataIdxs, ysub, censsub, javaparams);
                end
                java.lang.System.gc;
			else
				Xsub = model.X(this_r, :);
                model.module{m}.T = fh_simple_random_regtreefit_algoParams_instFeats_c(Xsub, ysub, censsub, Splitmin, ratioFeatures, model.cat, model.catDomains, seed, model.options.kappa_max, model.options.logModel, model.options.overallobj);
			end
        end
        if isjavarf
            model.P = RandomForest.preprocessForest(model.T, model.all_instance_features);
        end
    catch ME
        maxMemory = java.lang.Runtime.getRuntime.maxMemory
        totalMemory = java.lang.Runtime.getRuntime.totalMemory
        freeMemory = java.lang.Runtime.getRuntime.freeMemory
        
        savename = parsePath('saved_workspace.mat', model.options.workspace_savedir);
        bout(['Error building model. Saving workspace to ', savename, '\n']);
        save(savename);
        ME.rethrow();
    end
end
    
if ~isempty(strfind(model.type, 'GP'))
    global gprParams;
    gprParams = [];
    gprParams.combinedcat = model.cat;
    gprParams.combinedcont = model.cont;
    
    sigma_sqr_e = exp(2*model.params(end));
    model.var = exp(2*model.params(end-1));
    model.g = (model.var)/(model.var+sigma_sqr_e);
    
    if isfield(model.options, 'ppSize') && model.options.ppSize > 0
        %=== GP with subset of regressors or projected progress
        if any(model.cens)
            error('No censoring implemented yet for SRPP')
        end
        if nargout == 1
            if nargin > 1
                [model.Kmm, model.invKmm, model.saved_1, model.saved_2] = gprSRPPprepare(model.params, model.covfunc, model.X, model.pp_index, model.y, invKmm);
            else
                [model.Kmm, model.invKmm, model.saved_1, model.saved_2] = gprSRPPprepare(model.params, model.covfunc, model.X, model.pp_index, model.y); 
            end
        else
            error('prepareModel can only have 1 output if we use SRPP')
        end
    else
        %=== Normal GP
        if any(model.cens)
            model.useCensoring = 1;
            if nargout == 1
                [model.L_nonoise, model.alpha_nonoise, model.invK_times_invH_times_invK] = gprCensorPrepare(model.params, model.covfunc, model.X, model.y, model.cens);
            else
                error('prepareModel can only have 1 output if we use censoring')
            end
        else
            if nargout == 1
                [model.K, model.L, model.invL, model.alpha] = gprPrepare(model.params, model.covfunc, model.X, model.y);
            elseif nargout == 2
                [model.K, model.L, model.invL, model.alpha, nlml] = gprPrepare(model.params, model.covfunc, model.X, model.y);
            elseif nargout == 3
                [model.K, model.L, model.invL, model.alpha, nlml, dnlml, dKs] = gprPrepare(model.params, model.covfunc, model.X, model.y);
            else
                error('prepareModel needs to have at least 1 and not more than 3 outputs')
            end
        end
    end
end

model.prepared = 1;
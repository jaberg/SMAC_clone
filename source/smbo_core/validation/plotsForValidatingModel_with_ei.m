function valStats = plotsForValidatingModel_with_ei(options, model, f_min_samples, valdata, valStats, rundata)

global TestTheta;
global ThetaUniqSoFar;

%need to pass the right params

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL VALIDATION BASED ON POINTS EVALUATED OFFLINE.
% VISUALIZATION FOR THE 1-D CASE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if options.valid || options.just_valid
    %=== Plot expected improvement of validation points vs.
    %=== their actual performance.
    neg_ei_valid = neg_ei_of_model(TestTheta(-valdata.dev_theta_idxs,:), model, options.expImpCriterion, f_min_samples);

    %=== Weighted by ranks of expected improvement.
%    weights_ei = get_weights(neg_ei_valid);
%    [rmse_ei, ll_ei, cc_ei] = measures_of_fit(log10(valdata.valActualObjTest), valdata.valObjMu, valdata.valObjVar, zeros(length(valdata.valObjMu),1), weights_ei);
%    bout(sprintf(strcat(['Val, weighted by ranks of expected improvement, at iteration ', num2str(valdata.iteration), ': RMSE=', num2str(rmse_ei), ', CC=', num2str(cc_ei), ', LL=', num2str(ll_ei), '\n'])));

%     [tmp, sort_idx] = sort(neg_ei_valid);
%     N = length(neg_ei_valid);
%     for i=1:N
%         ranks_ei(sort_idx(i),1) = i;
%     end
%     [tmp, sort_idx] = sort(valdata.valActualObjTest);
%     for i=1:N
%         ranks_true(sort_idx(i),1) = i;
%     end
%     cc = corrcoef( ranks_ei, ranks_true );
%     bout(sprintf(strcat(['Correlation of ranks of exp. imp. and actual quality, at iteration ', num2str(valdata.iteration), ': ', num2str(cc(1,2)), '\n'])));

    [tmp_rmse, tmp_ll, tmp_cc, cc_rank_ei_goodness] = measures_of_fit(valdata.valActualObjTest, neg_ei_valid, zeros(length(neg_ei_valid),1), zeros(length(neg_ei_valid),1), ones(length(neg_ei_valid),1));
    bout(sprintf(strcat(['Correlation of ranks of exp. imp. and actual quality, at iteration ', num2str(valdata.iteration), ': ', num2str(cc_rank_ei_goodness), '\n'])));

    if length(valdata.valActualObjTest) > 100
        good_idx = 101:length(valdata.valActualObjTest);
        [tmp_rmse, tmp_ll, tmp_cc, cc_rank_ei_goodness] = measures_of_fit(valdata.valActualObjTest(good_idx), neg_ei_valid(good_idx), zeros(length(neg_ei_valid),1), zeros(length(neg_ei_valid(good_idx)),1), ones(length(neg_ei_valid(good_idx)),1));
        bout(sprintf(strcat(['Correlation on good configs, of ranks of exp. imp. and actual quality, at iteration ', num2str(valdata.iteration), ': ', num2str(cc_rank_ei_goodness), '\n'])));
    end

    
    valStats.cc_rank_ei_goodness = cc_rank_ei_goodness;
    if ~options.valid
        return
    end
    
    if options.plot_ei 
        figure(6);
        [valdata.valObjMu, valdata.valObjVar] = applyMarginalModel(model, TestTheta(-valdata.dev_theta_idxs,:), [], 0, 0);
        mini = min( min(min(valdata.valObjMu)), min(min(valdata.valObjMu-sqrt(valdata.valObjVar))) );
        maxi = max( max(max(valdata.valObjMu)), max(max(valdata.valObjMu+sqrt(valdata.valObjVar))) );
    
        plot_neg_ei_valid = N-ranks_ei;
        norm_ei = plot_neg_ei_valid/sum(plot_neg_ei_valid);
        max_ei = max(norm_ei);
        plot(log10(valdata.valActualObjTest), norm_ei/max_ei * abs(maxi-mini) + mini, 'bx', 'Markersize', 5);
    
        if valdata.iteration == valdata.next_iteration_to_output && valdata.numRun < valdata.numRunsToSaveDetails % only save the figures for the first 3 runs to save disk space
            fix_p = strcat(valdata.figure_prefix, 'val');
            set(gcf, 'PaperPositionMode', 'auto');
            filename = strcat(fix_p, 'pred.eps');
            fprintf(strcat(['Saving plot to ', filename]));
            print('-depsc2', filename);
            saveas(gcf, strcat(fix_p,'pred.fig'));
        end
    end

    if size(ThetaUniqSoFar,2)==1
        %=== For 1-D test function, we can plot the resulting predictions.
        figure(2)
        hold off;
        [Xsort, sort_idx] = sort(TestTheta(-valdata.dev_theta_idxs,:));
        trueval = valdata.valActualObjTest(sort_idx);
        predmu = valdata.valObjMu(sort_idx);
        predvar = valdata.valObjVar(sort_idx);

        h=confplot(Xsort, predmu, 2*sqrt(predvar), 2*sqrt(predvar), 'k:', 'LineWidth', 2);
        hold on;
        if options.logModel == 1 || options.logModel == 3
            h2=plot(Xsort, log10(trueval), 'r-', 'LineWidth', 2);
            h3=plot(ThetaUniqSoFar(rundata.used_theta_idxs,:), log10(rundata.y), 'bo', 'Markersize', 8, 'LineWidth', 2);
        else
            h2=plot(Xsort, trueval, 'r-', 'LineWidth', 2);
            h3=plot(ThetaUniqSoFar(rundata.used_theta_idxs,:), rundata.y, 'bo', 'Markersize', 8, 'LineWidth', 2);
        end
        %    axis([0,5,-5,2]);
        %    axis([0,5,-5,2]);

        new_theta_configs = 0:0.0001:1;
        new_theta_configs = new_theta_configs(:);
        neg_ei_new0 = neg_ei_of_model(new_theta_configs, model, model.options.expImpCriterion, f_min_samples);
        maxpoint = max(max(abs(rundata.y)), max(abs(trueval)));
        if options.logModel == 1 || options.logModel == 3
            maxpoint = log10(maxpoint);
            axis([0,1,min(-3, min(log10(rundata.y))-1),maxpoint+3])
        end
        h4=plot(new_theta_configs, -neg_ei_new0/(max(-neg_ei_new0))*maxpoint/2, 'g--', 'LineWidth', 3);
        hXLabel = xlabel('parameter x');
        hYLabel = ylabel('response y');

        set(h4                            , ...
            'Color'           , [.3 .7 .3]  , ...
            'LineWidth'       , 3 );

        switch options.modelType
            case 'GPML'
                modelString = 'GP';
            case 'dace'
                modelString = 'DACE';
            case {'rf', 'javarf', 'fastrf'}
                modelString = 'RF';
            otherwise
                modelString = options.modelType;
        end
        
        legend([h(1),h(2),h2,h3,h4], {strcat([modelString, ' mean prediction']), strcat([modelString, ' mean +/- 2*stddev']), 'True function', 'Function evaluations', 'EI (scaled)'}, 'location', 'NorthEast')
        set(gca, 'LineWidth', 1  );
        set([hXLabel, hYLabel], 'FontSize', 20);
        
        set(gcf, 'PaperPositionMode', 'auto');
        prefix = strcat([valdata.figure_prefix, '-', modelString, '-', num2str(valdata.iteration)]);
        filename = strcat(prefix, '.pdf');
        %filename = strcat(prefix, '.eps');
        %fprintf(strcat(['Saving plot to ', filename]));
        %print('-depsc2', filename);
        if exist(filename, 'file')
            delete(filename);
        end
        export_fig(filename);
        filename = strcat(prefix, '.fig');
        saveas(gcf, filename);
        %    close;z
    end
end
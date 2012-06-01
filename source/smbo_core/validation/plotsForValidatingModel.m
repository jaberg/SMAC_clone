function [valObjMu, valObjVar, valStats] = plotsForValidatingModel(options, model, dev_theta_idxs, tuningScenario, valActualObjTest, saving, iteration, next_iteration_to_output, numRun, numRunsToSaveDetails, figure_prefix, all_features_for_training_instances, overallobj, func, valTrueMatrixNoTrafo)
global TestTheta;
%=== Model validation.
valStats = [];

% idx = 1:length(valid); % plot everything
% idx = setdiff(idx, 101); % plot all but first "good" test point (the default)
% 
% valid = valid(idx);
% dev_theta_idxs = dev_theta_idxs(idx);


if options.valid || options.just_valid

    [valObjMu, valObjVar] = applyMarginalModel(model, TestTheta(-dev_theta_idxs,:), [], 0, 0);
    valObjStd = sqrt(valObjVar);

    if options.logModel == 1 || options.logModel == 3
        [rmse, ll, cc, cc_rank] = measures_of_fit(log10(valActualObjTest), valObjMu, valObjVar);
        bout(sprintf(strcat(['Val at iteration ', num2str(iteration), ': RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), ', CC_rank=', num2str(cc_rank), '\n'])));

        %=== Weighted by ranks of true quality.
        weights_true = get_weights(valActualObjTest);
        [rmse_true, ll_true, cc_true] = measures_of_fit(log10(valActualObjTest), valObjMu, valObjVar, zeros(length(valObjMu),1), weights_true);
%        bout(sprintf(strcat(['Val, weighted by ranks of true quality, at iteration ', num2str(iteration), ': RMSE=', num2str(rmse_true), ', CC=', num2str(cc_true), ', LL=', num2str(ll_true), '\n'])));

        %=== Weighted by ranks of predicted mean quality.
        weights_pred = get_weights(valObjMu);
        [rmse_pred, ll_pred, cc_pred] = measures_of_fit(log10(valActualObjTest), valObjMu, valObjVar, zeros(length(valObjMu),1), weights_pred);
%        bout(sprintf(strcat(['Val, weighted by ranks of pred mean quality, at iteration ', num2str(iteration), ': RMSE=', num2str(rmse_pred), ', CC=', num2str(cc_pred), ', LL=', num2str(ll_pred), '\n'])));
        titleStr = strcat(['Val: RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), ', CC_rank=', num2str(cc_rank)]);

        if length(valObjMu) > 100
%            weights_good = [zeros(100,1); ones(length(valObjMu)-100, 1)];
%            [rmse_good, ll_good, cc_good, cc_rank_good] = measures_of_fit(log10(valActualObjTest), valObjMu, valObjVar, zeros(length(valObjMu),1), weights_good);
            good_idx = 101:length(valObjMu);
            [rmse_good, ll_good, cc_good, cc_rank_good] = measures_of_fit(log10(valActualObjTest(good_idx)), valObjMu(good_idx), valObjVar(good_idx), zeros(length(valObjMu(good_idx)),1));
            bout(sprintf(strcat(['Val on good configs, at iteration ', num2str(iteration), ': RMSE=', num2str(rmse_good), ', CC=', num2str(cc_good), ', LL=', num2str(ll_good), ', CC_rank=', num2str(cc_rank_good), '\n'])));
            titleStr = strcat([titleStr, '; on good: RMSE=', num2str(rmse_good), ', CC=', num2str(cc_good), ', LL=', num2str(ll_good), ', CC_rank=', num2str(cc_rank_good)]);
        end

        %plotLog(log10(valActualObjTest), valObjMu, valObjStd, figure_prefix, str, 8);
    else
        [rmseNonLog, ll, ccNonLog, ccNonLog_rank] = measures_of_fit(valActualObjTest, valObjMu, valObjVar);
        idx_g_zero = find(valObjMu > 0);
        [rmse, tmp, cc, cc_rank] = measures_of_fit(log10(valActualObjTest(idx_g_zero)), log10(valObjMu(idx_g_zero)));
        bout(sprintf(strcat(['Val at iteration ', num2str(iteration), ': RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), ', ', num2str(length(find(valObjMu <= 0))), ' preds<=0,  RMSE_nonlog=', num2str(rmseNonLog), ', CC_nonlog=', num2str(ccNonLog), ', CC_rank=', num2str(cc_rank), ', CC_nonlog_rank=', num2str(ccNonLog_rank), '\n'])));
        titleStr = strcat(['Val: RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), ', CC=', num2str(cc_rank)]);
        %plotNonlog(options, figure_prefix, valActualObjTest, valObjMu, str, 9, valObjMu-valObjStd, valObjMu+valObjStd);
        
        if length(valObjMu) > 100
%            weights_good = [zeros(100,1); ones(length(valObjMu)-100, 1)];
%            [rmse_good, ll_good, cc_good, cc_rank_good] = measures_of_fit(log10(valActualObjTest), valObjMu, valObjVar, zeros(length(valObjMu),1), weights_good);
            good_idx = 101:length(valObjMu);%length(valObjMu)-100:length(valObjMu);
            [rmse_good, ll_good, cc_good, cc_rank_good] = measures_of_fit(valActualObjTest(good_idx), valObjMu(good_idx), valObjVar(good_idx), zeros(length(valObjMu(good_idx)),1));
            bout(sprintf(strcat(['Val on good configs, at iteration ', num2str(iteration), ': RMSE=', num2str(rmse_good), ', CC=', num2str(cc_good), ', LL=', num2str(ll_good), ', CC_rank=', num2str(cc_rank_good), '\n'])));
            titleStr = strcat([titleStr, '; on good: RMSE=', num2str(rmse_good), ', CC=', num2str(cc_good), ', LL=', num2str(ll_good), ', CC_rank=', num2str(cc_rank_good)]);
        end
        
    end
    valStats.rmse = rmse;
    valStats.ll = ll;
    valStats.cc = cc;
    valStats.cc_rank = cc_rank;

%     valStats.rmse_good = rmse_good;
%     valStats.ll_good = ll_good;
%     valStats.cc_good = cc_good;
%     valStats.cc_rank_good = cc_rank_good;
    
    if options.just_valid && ~options.valid
        return
    end

    if ~options.logModel
        titleStr = strcat([titleStr, ', ', num2str(length(find(valObjMu <= 0))), ' preds<=0,  RMSE_nonlog=', num2str(rmseNonLog), ', CC_nonlog=', num2str(ccNonLog), 'CC_nonlog_rank', num2str(ccNonLog_rank)]);
    end

    %=== Plot the figures.
    if saving && iteration == next_iteration_to_output && numRun < numRunsToSaveDetails
        fig_prefix = strcat(figure_prefix, 'val');
    else
        fig_prefix = '';
    end
%     plot_diagnostic_figures(valActualObjTest, valObjMu, valObjVar, zeros(length(valObjMu),1), rmse, cc, ll, fig_prefix, titleStr, model.options.logModel, 1);

    %        bout(sprintf(strcat(['Combined param model at it ', num2str(iteration), ': RMSE ', num2str(rmse), '; LL ', ...
    %            num2str(ll), '; CC ', num2str(cc), '; picked ', num2str(pickedActual), ' +/- ', num2str(stdPicked), '.\n'])));

    
 
    
    
    if options.matrix_validation
%         for i=1:size(TestTheta,1)
%             [allPredMeans, allPredVars] = applyModel(model, [repmat(TestTheta(-dev_theta_idxs(i),:), [size(all_features_for_training_instances,1),1]), all_features_for_training_instances], 0, 0);
%             matrixPredMean(i,:) = allPredMeans';
%             matrixPredVar(i,:) = allPredVars';
%         end
        for i=1:length(dev_theta_idxs)
            [allPredMeans, allPredVars] = applyModel(model, [repmat(TestTheta(-dev_theta_idxs(i),:), [size(all_features_for_training_instances,1),1]), all_features_for_training_instances], 0, 0);
            matrixPredMean(i,:) = allPredMeans';
            matrixPredVar(i,:) = allPredVars';
        end
        if options.logModel
            trans = 'log10';
        else
            trans = 'id';
        end
        matrixPredMean
%        [valObjPredNoTrafo, valAllPredMatricesNoTrafo, timeUsed] = fillMatricesAndComputeObjByLeafWalk(options, trans, overallobj, func, model, TestTheta(-dev_theta_idxs,:), all_features_for_training_instances, idx_to_fill);

        %             valYLastPredAsVectorNoTrafo = reshape(valAllPredMatricesNoTrafo(:,:,end), [size(DEV_test_design,1) * N, 1]);
        %             bout(sprintf(['Validation of last model ...\n']));
        %             %=== Plot matrix element prediction against actual outcomes.
        %             str = 'last-matrix-test';
        %             [rmse_full, ll_full, cc_full] = plotAndStats(options, figure_prefix, valYAllTestAsVectorNoTrafo, valYLastPredAsVectorNoTrafo, str, 1, zeros(length(valYAllTestAsVectorNoTrafo),1), valCensAllTest);
        %
        %             bout(sprintf(strcat(['Last full model ', num2str(m), ' at it ', num2str(iteration), ': RMSE ', num2str(rmse_full), '; LL ', ...
        %                 num2str(ll_full), '; CC ', num2str(cc_full), '.\n'])));

%         valPredMatrixMeanNoTrafo = mean(valAllPredMatricesNoTrafo, 3);
%         valPredMatrixMedianNoTrafo = median(valAllPredMatricesNoTrafo, 3);
%         valPredMatrixStdNoTrafo = std(valAllPredMatricesNoTrafo, 0, 3);
%         valPredMatrixTrafodMeanBack = mean(valAllPredMatricesNoTrafo, 3);

        %=== Plot the individual predictions.
%         valTrueVecNoTrafo = valTrueMatrixNoTrafo(:);
%         valPredVecMeanNoTrafo = valPredMatrixMeanNoTrafo(:);
%         valPredVecMedianNoTrafo = valPredMatrixMedianNoTrafo(:);
%         valPredVecTrafodMeanBack = valPredMatrixTrafodMeanBack(:);

%         valPredVecMeanNoTrafo = min(valPredVecMeanNoTrafo, func.cutoff);
%         str = 'median-no-trafo';
%         [rmse_full_notrafo, ll_full_notrafo, cc_full_notrafo] = plotAndStats(options, figure_prefix, valTrueVecNoTrafo, valPredVecMedianNoTrafo, str, 1, zeros(length(valPredVecMeanNoTrafo),1), zeros(length(valPredVecMeanNoTrafo),1));
% 
%         bout(sprintf(strcat(['Median full preds no trafo at it ', num2str(iteration), ': RMSE ', num2str(rmse_full_notrafo), '; LL ', ...
%             num2str(ll_full_notrafo), '; CC ', num2str(cc_full_notrafo), '.\n'])));
% 
%         str = 'mean-no-trafo';
%         %            [rmse_full_notrafo, ll_full_notrafo, cc_full_notrafo] = plotAndStats(options, figure_prefix, valTrueVecNoTrafo, valPredVecMeanNoTrafo, str, 2, zeros(length(valPredVecMeanNoTrafo),1), zeros(length(valPredVecMeanNoTrafo),1), options.transformation1);
%         [rmse_full_notrafo, ll_full_notrafo, cc_full_notrafo] = plotAndStats(options, figure_prefix, valTrueVecNoTrafo, valPredVecMeanNoTrafo, str);
% 
%         bout(sprintf(strcat(['Mean full preds no trafo at it ', num2str(iteration), ': RMSE ', num2str(rmse_full_notrafo), '; LL ', ...
%             num2str(ll_full_notrafo), '; CC ', num2str(cc_full_notrafo), '.\n'])));
% 
%         str = 'mean-of-trafod-back';
%         %            [rmse_full_trafod, ll_full_trafod, cc_full_trafod] = plotAndStats(options, figure_prefix, valTrueVecNoTrafo, valPredVecTrafodMeanBack, str, 3, zeros(length(valPredVecMeanNoTrafo),1), zeros(length(valPredVecMeanNoTrafo),1), options.transformation1);
%         [rmse_full_trafod, ll_full_trafod, cc_full_trafod] = plotAndStats(options, figure_prefix, valTrueVecNoTrafo, valPredVecTrafodMeanBack, str);
%         bout(sprintf(strcat(['Mean full preds trafod at it ', num2str(iteration), ': RMSE ', num2str(rmse_full_trafod), '; LL ', ...
%             num2str(ll_full_trafod), '; CC ', num2str(cc_full_trafod), '.\n'])));
% 
%         % TODO: QRF for prediction of matrix entries.
% 
%         %=== Plot the matrices.
%         means1 = mean(valTrueMatrixNoTrafo,1);
%         means2 = mean(valTrueMatrixNoTrafo,2);
%         [tmp,ind1] = sort(means1);
%         [tmp,ind2] = sort(means2);
% 
%         figure(4);h=image(log10(valTrueMatrixNoTrafo(ind2,ind1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('true matrix'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         hold on
%         h=colorbar;
%         mini = min(min(log10(valTrueMatrixNoTrafo)));
%         maxi = max(max(log10(valTrueMatrixNoTrafo)));
%         set(h, 'YLim', [mini,maxi])
%         file_filename = strcat([figure_prefix, 'truematrix.eps'])
%         set(gcf, 'PaperPositionMode', 'auto');
%         print('-depsc2', file_filename);
%         %            saveas(h, file_filename);
% 
%         figure(5);h=image(log10(valPredMatrixMedianNoTrafo(ind2,ind1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('median pred matrix'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         hold on
%         h=colorbar;
%         set(h, 'YLim', [mini,maxi])
%         file_filename = strcat([figure_prefix, 'medianpredmatrixnotrafo.eps'])
%         set(gcf, 'PaperPositionMode', 'auto');
%         print('-depsc2', file_filename);
%         %            saveas(h, file_filename);
% 
%         figure(6);h=image(log10(valPredMatrixMeanNoTrafo(ind2,ind1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('mean pred matrix no trafo'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         hold on
%         h=colorbar;
%         set(h, 'YLim', [mini,maxi])
%         file_filename = strcat([figure_prefix, 'meanpredmatrixnotrafo.eps'])
%         set(gcf, 'PaperPositionMode', 'auto');
%         print('-depsc2', file_filename);
%         saveas(h, file_filename);
% 
%         figure(7);h=image(log10(valAllPredMatricesNoTrafo(ind2,ind1,1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('1st tree pred matrix no trafo'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         hold on
%         h=colorbar;
%         set(h, 'YLim', [mini,maxi])
%         file_filename = strcat([figure_prefix, 'predmatrixnotrafo-1st_tree.eps'])
%         set(gcf, 'PaperPositionMode', 'auto');
%         print('-depsc2', file_filename);
%         saveas(h, file_filename);
% 
%         %             figure(8);h=image(log10(valAllPredMatricesNoTrafo(ind2,ind1,2)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('1st tree pred matrix no trafo'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         %             hold on
%         %             h=colorbar;
%         %             set(h, 'YLim', [mini,maxi])
%         %             file_filename = strcat([figure_prefix, 'predmatrixnotrafo-1st_tree.eps'])
%         %             set(gcf, 'PaperPositionMode', 'auto');
%         %             print('-depsc2', file_filename);
%         %             saveas(h, file_filename);
% 
%         %             figure(9);h=image(log10(valPredMatrixTrafodMeanBack(ind2,ind1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('mean trafod matrix backtrafod'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
%         %             hold on
%         %             h=colorbar;
%         %             set(h, 'YLim', [mini,maxi])
%         %             file_filename = strcat([figure_prefix, 'meantrafodpredmatrixback.eps'])
%         %             set(gcf, 'PaperPositionMode', 'auto');
%         %             print('-depsc2', file_filename);
%         %             saveas(h, file_filename);


        %=== Plot the matrices.
        means1 = mean(valTrueMatrixNoTrafo,1);
        means2 = mean(valTrueMatrixNoTrafo,2);
        [tmp,ind1] = sort(means1);
        [tmp,ind2] = sort(means2);

        figure(4);h=image(log10(valTrueMatrixNoTrafo(ind2,ind1)), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('true matrix'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
        hold on
        h=colorbar;
        mini = min(min(log10(valTrueMatrixNoTrafo)));
        maxi = max(max(log10(valTrueMatrixNoTrafo)));
        set(h, 'YLim', [mini,maxi])
        file_filename = strcat([figure_prefix, 'truematrix.eps'])
        set(gcf, 'PaperPositionMode', 'auto');
        print('-depsc2', file_filename);
        %            saveas(h, file_filename);

        figure(7); hold off; h=image(matrixPredMean(ind2,ind1), 'CDataMapping', 'scaled'); colormap(gray); hold on; title('mean pred'); ylabel('config id (sorted by true goodness)'); xlabel('instance id (sorted by true hardness)');
        hold on
        h=colorbar;
        set(h, 'YLim', [mini,maxi])
        file_filename = strcat([figure_prefix, 'predmatrixnotrafo.eps'])
        set(gcf, 'PaperPositionMode', 'auto');
        print('-depsc2', file_filename);
        saveas(h, file_filename);
    end
end

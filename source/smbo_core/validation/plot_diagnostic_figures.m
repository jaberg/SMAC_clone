function plot_diagnostic_figures(y, y_cross, y_cross_var, cens, rmse, cc, ll, figure_prefix, title_prefix, logModel, meanRT, grey)
idx = 1:length(y); % plot everything

idx = setdiff(idx, 101); % plot all but first "good" test point (default)
%idx = setdiff(idx, [184,185]); % plot all but first "good" test point (default)

y = y(idx);
y_cross = y_cross(idx);
y_cross_var = y_cross_var(idx);
cens = cens(idx);

general_response = 1;

if nargin < 12
    grey = 0;
    if nargin < 11
        meanRT = 0;
    end
end
nCross = length(y_cross);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% observed values vs. cross-validated prediction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cens_idx=find(cens==1);
uncens_idx=find(cens==0);

if ~logModel
    %=== Create a log plot of the positively predicted data.
    sfigure(5);
    hold off
    %hE     = loglog(y(find(y_cross>0)), y_cross(find(y_cross>0)));

    if length(y) > 100 && (~grey)
        idx = 1:100;
        yplot1 = log10(y(idx(find(y_cross(idx)>0))));
        ycross_plot1 = log10(y_cross(idx(find(y_cross(idx)>0))));
        hE1     = plot(yplot1, ycross_plot1);
        hold on
        
        idx = 101:length(y);
        yplot2 = log10(y(idx(find(y_cross(idx)>0))));
        ycross_plot2 = log10(y_cross(idx(find(y_cross(idx)>0))));
        hE2     = plot(yplot2, ycross_plot2);
        
        set(hE1, 'MarkerFaceColor' , [1 0 0]);
        set(hE2, 'MarkerFaceColor' , [0 1 0]);
        
        mini1 = min(min(yplot1), min(ycross_plot1))-0.1;
        maxi1 = max(max(yplot1), max(ycross_plot1))+0.1;

        mini2 = min(min(yplot2), min(ycross_plot2))-0.1;
        maxi2 = max(max(yplot2), max(ycross_plot2))+0.1;

        mini = min(mini1, mini2);
        maxi = max(maxi1, maxi2);
    else
        yplot = log10(y(find(y_cross>0)));
        ycross_plot = log10(y_cross(find(y_cross>0)));
        hE1     = plot(yplot, ycross_plot);
        hE2 = hE1;
        set( hE1, 'MarkerFaceColor' , [.7 .7 .7]  );

        mini = min(min(yplot), min(ycross_plot))-0.1;
        maxi = max(max(yplot), max(ycross_plot))+0.1;
    end

    hold on
    

%     mini = max(min(min(y)/2, min(y_cross)/2), 1e-10);
%     maxi = max(max(y), max(y_cross))*2;

    if meanRT
        if general_response
            hXLabel = xlabel('log_{10}(true mean response)');
            hYLabel = ylabel('log_{10}(predicted mean response)');
        else
            hXLabel = xlabel('log_{10}(true penalized average runtime [s])');
            hYLabel = ylabel('log_{10}(predicted penalized average runtime [s])');        
        end
    else
        if general_response
            hXLabel = xlabel('log_{10}(true response)');
            hYLabel = ylabel('log_{10}(predicted response)');
        else
            hXLabel = xlabel('log_{10}(true penalized runtime [s])');
            hYLabel = ylabel('log_{10}(predicted penalized runtime [s])');    
        end
    end
    [rmse_log, ll_log, cc_log] = measures_of_fit(log10(y(find(y_cross>0))), log10(y_cross(find(y_cross>0))));
    titleStr = strcat([title_prefix, ': RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll)]);
    titleStr = strcat([titleStr, ', ', num2str(length(find(y_cross <= 0))), ' preds<=0  RMSE_log=', num2str(rmse_log), ', CC_log=', num2str(cc_log)]);

%    bout(sprintf(strcat(['CV nonlog: RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), ', ', num2str(length(find(y_cross <= 0))), ' preds<=0  RMSE_log=', num2str(rmse_log), ', CC_log=', num2str(cc_log),'\n'])));
    
%    title(titleStr);
    hLine = line([mini, maxi],[mini,maxi]);

    set(hLine                         , ...
      'Color'           , [0 0 .5]    , ...
      'LineWidth'       , 2           );

    set([hE1,hE2]                            , ...
      'LineStyle'       , 'none'      , ...
      'Marker'          , '.'         , ...
      'Color'           , [.3 .3 .3]  , ...
      'LineWidth'       , 1           , ...
      'Marker'          , 'o'         , ...
      'MarkerSize'      , 6           , ...
      'MarkerEdgeColor' , [.2 .2 .2]      );
  
      set(gca, ...
      'Box'         , 'off'     , ...
      'TickDir'     , 'out'     , ...
      'XMinorTick'  , 'on'      , ...
      'YMinorTick'  , 'on'      , ...
      'FontSize'   , 14, ...
      'LineWidth'   , 1         );
%      'XTick'       , 10.^[-10:10], ...
%      'YTick'       , 10.^[-10:10], ...

  %'XColor'      , [.3 .3 .3], ...
  %    'YColor'      , [.3 .3 .3], ...

  
    axis([mini, maxi, mini, maxi]);
    set(gcf, 'Outerposition', [0,0,500,500]);

    set([hXLabel, hYLabel]  , ...
        'FontSize'   , 18          );

    if ~strcmp(figure_prefix, '')
        set(gcf, 'PaperPositionMode', 'auto');
        %print('-depsc2', strcat(figure_prefix, 'pred_log_no_errorbars.eps'))
        filename = strcat(figure_prefix, 'pred_log_no_errorbars.pdf');
        if exist(filename, 'file')
            delete(filename)
        end
        export_fig(filename);
        saveas(gcf, strcat(figure_prefix,'pred_log_no_errorbars.fig'));
%        close;
    end
end
    

sfigure(6);

if logModel == 1 || logModel == 3
    yplot = log10(y);
%tmp     mini = min(min(yplot), min(y_cross-sqrt(y_cross_var)))-0.1;
%tmp     maxi = max(max(yplot), max(y_cross+sqrt(y_cross_var)))+0.1;
%      mini = -1;
%      maxi = 2;
	mini = min(min(yplot), min(y_cross-sqrt(y_cross_var)))-0.1;
	maxi = max(max(yplot), max(y_cross+sqrt(y_cross_var)))+0.1;
else
    yplot = y;
    mini = min(min(y), min(y_cross))/1.1;
    maxi = max(max(y), max(y_cross))*1.1;
end
    
hold off
%tmphE1     = errorbar(yplot(1:min(100, length(yplot))), y_cross(1:min(100, length(yplot))), sqrt(y_cross_var(1:min(100, length(yplot)))), sqrt(y_cross_var(1:min(100, length(yplot)))));
hE1     = plot(yplot(1:min(100, length(yplot))), y_cross(1:min(100, length(yplot))));
hold on
if length(y) > 100 
%    hE2     = errorbar(yplot(101:end), y_cross(101:end), sqrt(y_cross_var(101:end)), sqrt(y_cross_var(101:end)));
    hE2     = plot(yplot(101:end), y_cross(101:end));
else
    hE2     = errorbar([], [], [], []);
end

if logModel == 1| logModel == 3
    if meanRT
        if general_response
            hXLabel = xlabel('log_{10}(true mean response)');
            hYLabel = ylabel('log_{10}(predicted mean response)');
        else
            hXLabel = xlabel('log_{10}(true penalized average runtime [s])');
            hYLabel = ylabel('log_{10}(predicted penalized average runtime [s])');        
        end
    else
        if general_response
            hXLabel = xlabel('log_{10}(true response)');
            hYLabel = ylabel('log_{10}(predicted response)');
        else
            hXLabel = xlabel('log_{10}(true penalized runtime [s])');
            hYLabel = ylabel('log_{10}(predicted penalized runtime [s])');    
        end
    end
else
    if general_response
        hXLabel = xlabel('true response');
        hYLabel = ylabel('predicted response');
    else
        hXLabel = xlabel('true penalized runtime [s]');
        hYLabel = ylabel('predicted penalized runtime [s]');    
    end
end

%titleStr = strcat([title_prefix, ': RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll)]);
%bout(sprintf(strcat(['CV: RMSE=', num2str(rmse), ', CC=', num2str(cc), ', LL=', num2str(ll), '\n'])));

%title(title_prefix);
hLine = line([mini, maxi],[mini,maxi]);

set(hLine                         , ...
  'Color'           , [0 0 .5]    , ...
  'LineWidth'       , 2           );

set([hE1,hE2]                     , ...
  'LineStyle'       , 'none'      , ...
  'Color'           , [.3 .3 .3]  , ...
  'LineWidth'       , 1           , ...
  'MarkerSize'      , 6           , ...
  'Marker'          , 'o'         , ...
  'MarkerEdgeColor' , [.2 .2 .2]);
%, ...
%  'MarkerFaceColor' , [.7 .7 .7]  );

if length(y) > 100 && (~grey)
    set(hE1, 'MarkerFaceColor' , [1 0 0]);
else
    set(hE1, 'MarkerFaceColor' , [.7 .7 .7]); %[.7 .7 .7]);
end
set(hE2, 'MarkerFaceColor' , [0 1 0]);
if grey
    set([hE1, hE2] , 'MarkerFaceColor' , [.7 .7 .7]);
end

% % adjust error bar width
% hE_c                   = ...
%     get(hE     , 'Children'    );
% errorbarXData          = ...
%     get(hE_c(2), 'XData'       );
% errorbarXData(4:9:end) = ...
%     errorbarXData(1:9:end) - 0.2;
% errorbarXData(7:9:end) = ....
%     errorbarXData(1:9:end) - 0.2;
% errorbarXData(5:9:end) = ...
%     errorbarXData(1:9:end) + 0.2;
% errorbarXData(8:9:end) = ...
%     errorbarXData(1:9:end) + 0.2;
% set(hE_c(2), 'XData', errorbarXData);

set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'XMinorTick'  , 'on'      , ...
  'YMinorTick'  , 'on'      , ...
  'XColor'      , [0 0 0], ...
  'YColor'      , [0 0 0], ...
        'FontSize'   , 14, ...
  'LineWidth'   , 2         );
%  'TickLength'  , [.02 .02] , ...
%  'YGrid'       , 'on'      , ...
%  'YTick'       , 0:500:2500, ...

%Xcolor [.3 .3 .3]

% if logModel
%     set(gca, ...
%   'XTick'       , 10.^[-10:10], ...
%   'YTick'       , 10.^[-10:10]      );
% end

axis([mini, maxi, mini, maxi]);

set([hXLabel, hYLabel]  , ...
    'FontSize'   , 18          );
set(gcf, 'Outerposition', [0,0,500,500]);

if ~strcmp(figure_prefix, '')
    set(gcf, 'PaperPositionMode', 'auto');
%    filename = strcat(figure_prefix, 'pred.eps');
%    fprintf(strcat(['Saving plot to ', filename]));
%    print('-depsc2', filename);
    filename = strcat(figure_prefix, 'pred.pdf');
    if exist(filename, 'file')
        delete(filename)
    end
    export_fig(filename);

    saveas(gcf, strcat(figure_prefix,'pred.fig'));
%    close;
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % standardized residual plot from the EGO paper.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% h=sfigure(7);
% hold off
% stand_res = 1e10 * ones(length(y_cross_var),1);
% nz_idx = find(y_cross_var>0);
% stand_res(nz_idx) = (yplot(nz_idx)-y_cross(nz_idx))./(y_cross_var(nz_idx).^0.5);
% 
% % if length(y) > 100
% %     idx = 1:100;
% %     uncens_idx_sub = uncens_idx(intersect(uncens_idx,idx));
% %     cens_idx_sub = cens_idx(intersect(cens_idx,idx));
% %     hUncens = semilogx(y(uncens_idx_sub), stand_res(uncens_idx_sub), 'ro');
% %     hold on
% %     hCens = semilogx(y(cens_idx_sub), stand_res(cens_idx_sub), 'rx');
% %     
% %     idx = 101:length(y);
% %     uncens_idx_sub = uncens_idx(intersect(uncens_idx,idx));
% %     cens_idx_sub = cens_idx(intersect(cens_idx,idx))-100;
% %     hUncens = semilogx(y(uncens_idx_sub), stand_res(uncens_idx_sub), 'go');
% %     hold on
% %     hCens = semilogx(y(cens_idx_sub), stand_res(cens_idx_sub), 'gx');
% %     
% %     hXLabel = xlabel('observed value');
% %     hYLabel = ylabel('standardized residual cross-validation error')
% % else
%     hUncens = semilogx(y(uncens_idx), stand_res(uncens_idx), 'ko');
%     hold on
%     hCens = semilogx(y(cens_idx), stand_res(cens_idx), 'kx');
%     if meanRT
%         %hXLabel = xlabel('true penalized average runtime [s]');
%         hXLabel = xlabel('true mean response');
%         hYLabel = ylabel('standardized residual error');
%     else
%         %hXLabel = xlabel('observed penalized runtime [s]');
%         hXLabel = xlabel('observed response');
%         hYLabel = ylabel('standardized residual CV error');
%     end
% % end
% hLine1 = line([min(y)/2, max(y)*2],[-3,-3]);
% hLine2 = line([min(y)/2, max(y)*2],[ 3, 3]);
% 
% set(hUncens                       , ...
%   'LineStyle'       , 'none'      , ...
%   'Marker'          , 'o'         , ...
%   'MarkerSize'      , 6           , ...
%   'MarkerFaceColor' , [1 1 1]); %[.7 .7 .7]  );
% %  'MarkerEdgeColor' , [.2 .2 .2]  , ...
% 
% set([hLine1, hLine2]              , ...
%   'Color'           , [0 0 .5]    , ...
%   'LineWidth'       , 2           );
% 
% set(gca, ...
%   'Box'         , 'off'     , ...
%   'TickDir'     , 'out'     , ...
%   'XMinorTick'  , 'on'      , ...
%   'YMinorTick'  , 'on'      , ...
%   'YGrid'       , 'on'      , ...
%   'XTick'       , 10.^[-10:10], ...
%       'FontSize'   , 14, ...  
%   'LineWidth'   , 1         );
% %  'TickLength'  , [.02 .02] , ...
% %  'YTick'       , 0:500:2500, ...
% 
% set(gcf, 'Outerposition', [0,0,500,500]);
% %  'XColor'      , [.3 .3 .3], ...
% %  'YColor'      , [.3 .3 .3], ...
% 
% 
% axis([min(y)/2, max(y)*2, min(min(stand_res)-0.01, -3.5), max(max(stand_res)+0.01, 3.5)]);
% 
% set([hXLabel, hYLabel]  , ...
%     'FontSize'   , 18          );
% 
% if ~strcmp(figure_prefix, '')
%     set(gcf, 'PaperPositionMode', 'auto');
% %    filename = strcat(figure_prefix, 'err.eps');
% %    fprintf(strcat(['Saving plot to ', filename]));
% %    print('-depsc2', filename);
%     filename = strcat(figure_prefix, 'err.pdf');
%     if exist(filename, 'file')
%         delete(filename)
%     end
%     export_fig(filename);
%     saveas(gcf, strcat(figure_prefix,'err.fig'))
% %    close;
% end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % standardized normal quantile plot from the EGO paper.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nrand = randn(1,1000);
% real_q = [];
% my_q = [];
% %  stand_res = randn(1,40);
% for i=1:length(uncens_idx)
%     real_q(i) = quantile(nrand, (i+0.0)/(nCross+1.0));
%     my_q(i) = quantile(stand_res(uncens_idx), (i+0.0)/(nCross+1.0));
% end
% h=sfigure(8);
% hold off
% hDots = plot(real_q, my_q, 'ko', 'MarkerSize', 6);
% 
% hold on
% hXLabel = xlabel('standard normal quantile');
% hYLabel = ylabel('standardized residual quantile');
% mini = min(min(real_q), min(my_q)) - 0.5;
% maxi = max(max(real_q), max(my_q)) + 0.5;
% hLine = line([mini, maxi],[mini,maxi]);
% 
% set(hLine           , ...
%   'Color'           , [0 0 .5]    , ...
%   'LineWidth'       , 2           );
% 
% set(gca, ...
%   'Box'         , 'off'     , ...
%   'TickDir'     , 'out'     , ...
%   'XMinorTick'  , 'on'      , ...
%   'YMinorTick'  , 'on'      , ...
%   'YGrid'       , 'on'      , ...
%   'XGrid'       , 'on'      , ...
%       'FontSize'   , 14, ...  
%   'LineWidth'   , 1         );
% %  'TickLength'  , [.02 .02] , ...
% %  'YTick'       , 0:500:2500, ...
% 
% %  'XColor'      , [.3 .3 .3], ...
% %  'YColor'      , [.3 .3 .3], ...
% 
% 
% axis([mini, maxi, mini, maxi]);
% set(gcf, 'Outerposition', [0,0,500,500]);
%     
% set([hXLabel, hYLabel]  , ...
%     'FontSize'   , 18          );
% 
% if ~strcmp(figure_prefix, '')
%     set(gcf, 'PaperPositionMode', 'auto');
% %    filename = strcat(figure_prefix, 'qq.eps');
% %    fprintf(strcat(['Saving plot to ', filename]));
% %    print('-depsc2', filename);
%     filename = strcat(figure_prefix, 'qq.pdf');
%     if exist(filename, 'file')
%         delete(filename)
%     end
%     export_fig(filename);
% 
%     saveas(gcf, strcat(figure_prefix,'qq.fig'));
% %    close;
end
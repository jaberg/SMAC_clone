%=== Plot matrix element prediction against actual outcomes.
% trueVal, pred, std are taken in the log domain - that's what we use to get RMSE, CC, and LL.

function [rmse, ll, cc, meanPicked, stdPicked] = plotAndStatsLog(trueVal, pred, std, figure_prefix, str, figureNo)
if nargin < 6
    figure;
    if nargin < 5
        titleStr = 'Pred';
        if nargin < 4
            figure_prefix = '';
        end
    end
else
    figure(figureNo);
end

[rmse, ll, cc] = measures_of_fit(trueVal, pred, std.^2, zeros(length(pred),1));
% s=rand('twister');
% [pickedActual, pickedConservativeActual, defaultActual, avgActual, bestActual, worstActual, randActual, meanPicked, stdPicked, meanPickedCons, stdPickedCons] = evalPickedPerformance(trueVal, pred, pred+std, 'id');
% rand('twister', s);
% titleStr = strcat(str, '-rmse', num2str(rmse), '-cc', num2str(cc), '-LL', num2str(ll), '-pick', num2str(meanPicked));
titleStr = strcat(str, '-rmse', num2str(rmse), '-cc', num2str(cc), '-LL', num2str(ll));

if nargin < 4
    return
end
%trueVal = trafo(trueVal, trans);
%pred = trafo(pred, trans);

hold off

if any(std)
    predLow = pred-std;
    predHigh = pred+std;

    mini = min(min(trueVal), min(predLow))-0.1;
    maxi = max(max(trueVal), max(predHigh))+0.1;
    hE1    = errorbar(trueVal(1:100), pred(1:100), pred(1:100)-predLow(1:100), predHigh(1:100)-pred(1:100));
    hold on
    hE2    = errorbar(trueVal(101:end), pred(101:end), pred(101:end)-predLow(101:end), predHigh(101:end)-pred(101:end));
    %    errorbarlogx(0.1);
    set([hE1,hE2]                            , ...
    'LineStyle'       , 'none'      , ...
    'Marker'          , '.'         , ...
    'Color'           , [.3 .3 .3]  ,...
      'LineWidth'       , 1           , ...
      'MarkerSize'      , 5           , ...
      'MarkerEdgeColor' , [.2 .2 .2]  , ...
      'MarkerFaceColor' , [.7 .7 .7]  );
    %  'MarkerFaceColor' , 'r'  );
    set(hE1,  'Marker'          , 'o');
    set(hE1,  'Marker'          , 'x');


else
    hMeans = loglog(trueVal, pred, '.');
    hold on
    mini = min(min(trueVal), min(pred));
    if mini < 0
        mini = mini*1.1;
    else
        mini = mini/1.1;
    end
    maxi = max(max(trueVal), max(pred));
    if maxi < 0
        maxi = maxi/1.1;
    else
        maxi = maxi*1.1;
    end
end

hLine=line([mini, maxi],[mini, maxi]);
axis([mini maxi mini maxi]);
file_filename = strcat([figure_prefix, str, '.eps']);
title(titleStr);
set(gcf, 'PaperPositionMode', 'auto');
%print('-depsc2', file_filename);
%saveas(hLine, file_filename);

%=== Plot matrix element prediction against actual outcomes.
% trueVal, pred, std are untransformed - we take log10 to compute RMSE and
% CC, but not for LL.

function [rmse, ll, cc, meanPicked, stdPicked] = plotAndStatsNew(trueVal, pred, std, figure_prefix, str, figureNo)

error 'was not used anymore as of 11 feb 2009, so no longer maintained'

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
assert(all(trueVal>0));
assert(all(pred>0));

[rmse, ll, cc] = measures_of_fit(trueVal, pred, std.^2, zeros(size(pred,1),1), 'log10');
s=rand('twister')
[pickedActual, pickedConservativeActual, defaultActual, avgActual, bestActual, worstActual, randActual, meanPicked, stdPicked, meanPickedCons, stdPickedCons] = evalPickedPerformance(trueVal, pred, pred+std, 'id');
rand('twister', s);


titleStr = strcat(str, '-rmse', num2str(rmse), '-cc', num2str(cc), '-LL', num2str(ll), '-pick', num2str(meanPicked));

if nargin < 4
    return
end
%trueVal = trafo(trueVal, trans);
%pred = trafo(pred, trans);

hold off

if any(std)
    predLow = max(pred-std, min(trueVal));
    predHigh = pred+std;

    if 0
        mini = min(min(trueVal), min(pred-std))/1.1;
        maxi = max(max(trueVal), max(pred+std))*1.1;
%            hE     = errorbarloglog(trueVal', pred', pred'-predLow', predHigh'-pred');
        hE     = errorbarloglog(trueVal', pred', predLow', predHigh', 'none', '.', [.3 .3 .3]);
        hold on
        tmp=get(hE, 'Children');
        set(tmp(1), ...
            'LineWidth'       , 1           , ...
          'Marker'          , 'o'         , ...
          'MarkerSize'      , 5           , ...
          'MarkerEdgeColor' , [.2 .2 .2]  , ...
          'MarkerFaceColor' , [.7 .7 .7]  );
%        otherwise
    else
        predLow = log10(predLow);
        predHigh = log10(predHigh);
        pred = log10(pred);
        trueVal = log10(trueVal);
        
        mini = min(min(trueVal), min(predLow))-0.1;
        maxi = max(max(trueVal), max(predHigh))+0.1;
        hE     = errorbar(trueVal, pred, pred-predLow, predHigh-pred);
        hold on
    %    errorbarlogx(0.1);
       set(hE                            , ...
      'LineStyle'       , 'none'      , ...
      'Marker'          , '.'         , ...
      'Color'           , [.3 .3 .3]  );
        set(hE                            , ...
          'LineWidth'       , 1           , ...
          'Marker'          , 'o'         , ...
          'MarkerSize'      , 5           , ...
          'MarkerEdgeColor' , [.2 .2 .2]  , ...
          'MarkerFaceColor' , [.7 .7 .7]  );
        %  'MarkerFaceColor' , 'r'  );
    end

else
    hMeans = loglog(trueVal, pred, '.');
    hold on
    mini = min(min(trueVal), min(pred))/1.1;
    maxi = max(max(trueVal), max(pred))*1.1;
end

hLine=line([mini, maxi],[mini, maxi]);
axis([mini maxi mini maxi]);
file_filename = strcat([figure_prefix, str, '.eps']);
title(titleStr);
set(gcf, 'PaperPositionMode', 'auto');
print('-depsc2', file_filename);
%saveas(hLine, file_filename);

%=== Plot matrix element prediction against actual outcomes.
% trueVal, pred, predLow and predHigh are untransformed !

function [rmse, ll, cc, meanPicked, stdPicked] = plotAndStats(al_opts, figure_prefix, trueVal, pred, titleStr, figureNo, predLow, predHigh)
if nargin < 8
    predHigh = zeros(length(trueVal), 1);
    if nargin < 7
        predLow = zeros(length(trueVal), 1);
    end
end

assert(all(trueVal>0));
%[rmse, ll, cc] = measures_of_fit(log10(trueVal(find(pred>0))), log10(pred(find(pred>0))));
[rmse, ll, cc, cc_rank] = measures_of_fit(trueVal, pred, (predHigh-pred).^2);
s=rand('twister');
%[pickedActual, pickedConservativeActual, defaultActual, avgActual, bestActual, worstActual, randActual, meanPicked, stdPicked, meanPickedCons, stdPickedCons] = evalPickedPerformance(trueVal, pred, predHigh, 'id');
rand('twister', s);

if nargin < 6
    return
end
titleStr = strcat(titleStr, '-rmse', num2str(rmse), '-cc', num2str(cc), '-LL', num2str(ll), '-ccrank', num2str(cc_rank));
%titleStr = strcat(titleStr, '-rmse', num2str(rmse), '-cc', num2str(cc), '-LL', num2str(ll), '-pick', num2str(meanPicked));

%trueVal = trafo(trueVal, trans);
%pred = trafo(pred, trans);

figure(figureNo);
hold off

assert(all(trueVal>0));
%assert(all(pred>0));


if any(predLow)
%    predLow = trafo(predLow, trans);
%    predHigh = trafo(predHigh, trans);
%    switch trans
%        case 'id'
    if 1
        mini = min(min(trueVal), min(predLow))/1.1;
        maxi = max(max(trueVal), max(predHigh))*1.1;
        hE     = errorbar(trueVal, pred, pred-predLow, predHigh-pred);
%            hE     = errorbarloglog(trueVal', pred',predLow', predHigh', 'none', '.', [.3 .3 .3]);
%        hE     = errorbarloglog(trueVal', pred', predLow', predHigh', 'none', '.', [.3 .3 .3]);
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
        trueVal = log10(trueVal);
        pred = log10(pred);                

        predLow = log10(max(predLow, 0.1));
        predHigh = log10(predHigh);
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
    hMeans = plot(trueVal, pred, '.');
    hold on
    mini = min(min(trueVal), min(pred))-0.1;
    maxi = max(max(trueVal), max(pred))+0.1;
end

hLine=line([mini, maxi],[mini, maxi]);
axis([mini maxi mini maxi]);
file_filename = strcat([figure_prefix, titleStr, '.eps']);
title(titleStr);
set(gcf, 'PaperPositionMode', 'auto');
%print('-depsc2', file_filename);
%saveas(hLine, file_filename);

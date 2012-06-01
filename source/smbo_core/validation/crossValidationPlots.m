function [rmse, cc, ll] = crossValidationPlots(model, plot_figures, k, figure_prefix)
if nargin < 3
    k = 10;
end
if nargin < 4
    figure_prefix = '';
end

%=== Compute cross validation predictions.
% nCross = length(y);
% y_cross = zeros(nCross,1);
% y_cross_var = zeros(nCross,1);
% for i=1:nCross
%     idx = setdiff(1:nCross, i);
%     crossModel = updateDataModel(model, X(idx,:), y(idx), cens(idx));
%     [y_cross(i), y_cross_var(i)] = applyModel(crossModel, X(i,:));
% end
% 
% rmse = sqrt(mean((y_cross-y).^2))
% cc = corrcoef(y_cross,y);
% cc=cc(1,2);
% ll = log_likelihood(y,y_cross,y_cross_var,cens)/length(y);

% if nargin < 6
%     model.al_opts.crossVal_ll_k = length(model.y);
% else
    model.al_opts.crossVal_ll_k = k;
% end

[rmse, ll, cc, y_cross, y_cross_var] = crossValidation(model);

if plot_figures
    ytoplot = model.origY;
    censtoplot = model.cens;
    
    len_indices_to_plot = 100;
    if length(y_cross) > len_indices_to_plot
        perm = randperm(len_indices_to_plot);
        indices_to_plot = perm(1:len_indices_to_plot);

        y_cross = y_cross(indices_to_plot);
        y_cross_var = y_cross_var(indices_to_plot);
        ytoplot = ytoplot(indices_to_plot);
        censtoplot = model.cens(indices_to_plot);
    end
    
%     if strfind(model.type, 'GP')
%         ytoplot = 10.^model.y;
%     end
    plot_diagnostic_figures(ytoplot, y_cross, y_cross_var, censtoplot, rmse, cc, ll, figure_prefix, strcat('CV-',num2str(k)), model.al_opts.logModel, 0);
end

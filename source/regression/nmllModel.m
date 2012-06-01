function [nmll, dnmll] = nmllModel(params, model)
if size(params,2) > 1
    if size(params,1) > 1
        error 'params has to be a vector'
    else
        params = params(:);
    end
end

% nmllModel: returns minus the log likelihood and 
% its partial derivatives with respect to the hyperparameters; 
% this can be used to fit the hyperparameters.
%
% [nmll, dnmll] = nmllModel(logtheta, model);

model.params = params;
if nargout == 1
    [model, nmll] = prepareModel(model);
elseif nargout == 2 
    [model, nmll, dnmll] = prepareModel(model);
else
    error('nmllModel has one or two outputs.')
end
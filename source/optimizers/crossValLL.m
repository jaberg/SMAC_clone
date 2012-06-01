function nll = crossValLL(params, model)
% crossValLL(logtheta, model)
% Evaluate the negative cross-validated likelihood of hold-out data
% under a predictive model with log hyperparameters logtheta.
% Also returns an updated model

if size(params,2) > 1
    if size(params,1) > 1
        error 'params has to be a vector'
    else
        params = params(:);
    end
end

model.params = params;
%tic;
[rmse, ll, cc] = crossValidation(model);
%time_for_one_cv = toc
nll = -ll;
function rmse = crossValRMSE(params, model)
% crossValRMSE(logtheta, model)
% Evaluate the RMSE of hold-out data
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
[rmse, ll, cc] = crossValidation(model);
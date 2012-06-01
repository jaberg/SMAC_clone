function [min_x, min_val, bestconflist, model, incumbent_theta_idx, func, options, rundata] = smbo_wrap_simple(inputFuncHandle, x_init, lb, ub, maxFunEvals, options)
if (nargin < 5)
    options = struct([]);
end
tempOptions = [];

% tempOptions.onlyOneChallenger = 1;
options.frac_rawruntime = 0;
tempOptions.logModel = 0;
tempOptions.maxn = 1;
tempOptions.writeToScreen = 0;
tempOptions.expImpCriterion = 3;
tempOptions.nInit = maxFunEvals/10;% length(x_init); 
% tempOptions.Splitmin_init = 1;
% tempOptions.orig_rf = 0;

for opt = fieldnames(options)'
    tempOptions.(char(opt)) = options.(char(opt));
end
options = tempOptions;
options.totalNumRunLimit = maxFunEvals;

lb = lb(:);
ub = ub(:);
func.cont = 1:length(lb);
func.param_bounds = [lb, ub];
func.default_values = x_init(:);
func.name = func2str(inputFuncHandle);
func.inputFuncHandle = @(theta, instance_numbers, seeds, censorLimits) inputFuncHandle(theta);
func.external = 0;
func.deterministic = 1;

[min_x, min_val, bestconflist, model, incumbent_theta_idx, func, options, rundata] = smbo(func,options);
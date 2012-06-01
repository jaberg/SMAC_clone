function [out1, out2] = gpr(logtheta, covfunc, x, y, cens, xstar);

% gpr - Gaussian process regression, with a named covariance function. Two
% modes are possible: training and prediction: if no test data are given, the
% function returns minus the log likelihood and its partial derivatives with
% respect to the hyperparameters; this mode is used to fit the hyperparameters.
% If test data are given, then (marginal) Gaussian predictions are computed,
% whose mean and variance are returned. Note that in cases where the covariance
% function has noise contributions, the variance returned in S2 is for noisy
% test targets; if you want the variance of the noise-free latent function, you
% must substract the noise variance.
%
% usage: [nlml dnlml] = gpr(logtheta, covfunc, x, y)
%    or: [mu S2]  = gpr(logtheta, covfunc, x, y, xstar)
%
% where:
%
%   logtheta is a (column) vector of log hyperparameters
%   covfunc  is the covariance function
%   x        is a n by D matrix of training inputs
%   y        is a (column) vector (of size n) of targets
%   xstar    is a nn by D matrix of test inputs
%   nlml     is the returned value of the negative log marginal likelihood
%   dnlml    is a (column) vector of partial derivatives of the negative
%                 log marginal likelihood wrt each log hyperparameter
%   mu       is a (column) vector (of size nn) of prediced means
%   S2       is a (column) vector (of size nn) of predicted variances
%
% For more help on covariance functions, see "help covFunctions".
%
% (C) copyright 2006 by Carl Edward Rasmussen (2006-03-20).

if ischar(covfunc), covfunc = cellstr(covfunc); end % convert to cell if needed
[n, D] = size(x);
if eval(feval(covfunc{:})) ~= size(logtheta, 1)
  error('Error: Number of parameters do not agree with covariance function')
end

K = feval(covfunc{:}, logtheta, x);    % compute training set covariance matrix
tmp = max(max(max(K)),1e-10);
K = K + tmp/1e10*eye(length(K)); %FH: min_noise for numerical stability


L = chol(K)';                        % cholesky factorization of the covariance
invR = L'\eye(n);
%invK = L'\(L\eye(n));
invL = L\eye(n);
invK = invR*invL;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NUMERICAL OPTIMIZATION TO FIND f_bar,
% i.e. the most likely f_{1:N} given y_{1:N} and cens_{1:N}
% (without censoring, f_bar = y)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cens_idx = find(cens==1);
noncens_idx = find(cens==0);

%=== Check if there is any noise (o/w set minimum noise).
if length(covfunc) ~= 2 | ~strcmp(covfunc(1), 'covSum') | ~strcmp(covfunc{2}(end), 'covNoise')
    sigma_n = 1e-10;
else
    sigma_n = sqrt(exp(2*logtheta(end)));           % sqrt(noise variance)
end

%=== Gradient optimizer to find best f_bar; initialize with y.
options.Method = 'lbfgs';
%options.iterations = 100;
%options.numDiff = 1; % until I have implemented the gradient.
options.Display = 'off';
warning off MATLAB:nearlySingularMatrix;
options.DerivativeCheck = 'on';

% Possible TODO: only optimize f_bar for the censored data points - use a
% conditional Gaussian for them given the uncensored points => lower
% dimensionality for the numerical optimization problem.
funcToOptimize = @(f) negLogCensoredConditional(f, y, cens, invL, invK, sigma_n);
f_bar = minFunc(funcToOptimize, y, options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Once we have f_bar, the rest is straight-forward.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

alpha = solve_chol(L',f_bar); % More efficient for: alpha=inv(K)*f_bar

if nargin == 5 % if no test cases, compute the negative log marginal likelihood
	error('Cannot compute the marginal likelihood in closed form under censoring')
else                    % ... otherwise compute (marginal) test predictions ...
  [Kss, Kstar] = feval(covfunc{:}, logtheta, x, xstar);     %  test covariances

  out1 = Kstar' * alpha;                                      % predicted means

  if nargout == 2
    v = L\Kstar;
    out2 = Kss - sum(v.*v)';
  end  
end

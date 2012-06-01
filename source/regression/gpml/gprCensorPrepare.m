function [L_nonoise, alpha_nonoise, CombRoot] = gprCensorPrepare(logtheta, covfunc, X, y, cens)

% gprCensorPrepare: performs all precomputation possible without test data.
% In contrast to gprPrepare, this does does NOT return minus the 
% log likelihood, because we have no closed form approximation for it.
% Also in contrast to gprPrepare, the returned matrices and vectors are
% all computed using a NOISE-FREE covariance function K, so they don't
% automatically add the noise term, because we need the noise-free terms
% for the censoring case.
%
% usage: [L_nonoise, alpha_nonoise, CombRoot] =
% gprCensorPrepare(logtheta, covfunc, X, y, cens)
%
% where
%   logtheta is a (column) vector of log hyperparameters
%   covfunc  is the covariance function
%   X        is a n by D matrix of training inputs
%   y        is a (column) vector (of size n) of targets
%   cens     is a (column) vector (of size n) of targets with cens(i)=1
%            indicating that y(i) is only a lower bound on the target for X(i,:)

if ischar(covfunc), covfunc = cellstr(covfunc); end % convert to cell if needed
[n, D] = size(X);
if eval(feval(covfunc{:})) ~= size(logtheta, 1)
    error('Error: Number of parameters do not agree with covariance function')
end

K = feval(covfunc{:}, logtheta, X);    % compute training set covariance matrix
min_noise_sigma = 1e-6;
%min_noise_sigma = 1e-2;  % relatively high, to enable the computation of pdfln((f-o)/sigma_n)
%=== Check if there is any noise, and if so, subtract it from K's diagonal.
if length(covfunc) == 2 & strcmp(covfunc(1), 'covSum') & strcmp(covfunc{2}(end), 'covNoise')
    sigma_n = sqrt(exp(2*logtheta(end)));           % sqrt(noise variance)
    K_nonoise = K - sigma_n*sigma_n*eye(n);
else
    K_nonoise = K;
    sigma_n = min_noise_sigma;
end
%tmp = max(max(max(K_nonoise)),1e-10);
K_nonoise = K_nonoise + min_noise_sigma^2*eye(n); %FH: add min_noise for numerical stability

L_nonoise = chol(K_nonoise)';                        % cholesky factorization of the covariance
invL_nonoise = L_nonoise\eye(n);
invK_nonoise = L_nonoise'\invL_nonoise;

cens_idx = find(cens==1);
noncens_idx = find(cens==0);

%=== Find f_bar, i.e. the most likely f_{1:N} given y_{1:N} and cens_{1:N}
% Use a gradient optimizer to find best f_bar, initialize with y.
% Possible TODO: only optimize f_bar for the censored data points - use a
% conditional Gaussian for them given the uncensored points => lower
% dimensionality for the numerical optimization problem.

%options.Method = 'lbfgs';
%options.Method = 'newton';
options.iterations = 100;
%options.numDiff = 1; % until I have implemented the gradient.
%options.Display = 'off'; %'on';%
warning off MATLAB:nearlySingularMatrix;
%options.DerivativeCheck = 'on';

funcToOptimize = @(f) negLogCensoredConditional(f, y, cens_idx, noncens_idx, invL_nonoise, invK_nonoise, sigma_n);
f_init = y;
addForCens_init = mean(abs(y));
f_init(cens_idx) = f_init(cens_idx) + addForCens_init; % Initialize the mean for censored values above the censoring threshold.
f_bar = minFunc(funcToOptimize, f_init, options);
%f_bar = minFunc(funcToOptimize, y+0.01, options);
%f_bar = minFunc(funcToOptimize, y, options);
H = getHessianOfNegLogCensoredConditional(f_bar, y, invK_nonoise, cens_idx, noncens_idx, sigma_n);

%=== Assert that the approximation is perfect in the absence of censoring.
% if ~any(cens)
%     assert(f_bar < y+0.1); 
%     assert(f_bar > y-0.1); 
% end
alpha_nonoise = solve_chol(L_nonoise',f_bar); % More efficient for: alpha_nonoise=inv(K_nonoise)*f_bar

M = chol(H)';                        % cholesky factorization of the Hessian, lower triangular
invM = M\eye(n);
CombRoot = invM * invK_nonoise;      % CombRoot' * CombRoot = invK_nonoise * inv(H) * invK_nonoise
% Assertion:
% tmp1 = CombRoot' * CombRoot;
% tmp2 = invK_nonoise * inv(H) * invK_nonoise;
% for i=1:n
%     for j=1:n
%         assert(abs(tmp1(i,j)-tmp2(i,j))/max(abs(tmp1(i,j)), abs(tmp2(i,j))) < 1e-5); 
%     end
% end
%=== Slower version: 
%=== invH = M'\invM;
%=== invK_times_invH_times_invK = invK_nonoise * inv(H) * invK_nonoise;
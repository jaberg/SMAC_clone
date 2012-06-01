function [out1, out2] = gprCensor(logtheta, covfunc, x, y, cens, xstar);
error('shouldnt be used anymore')
% gpr - Gaussian process regression, with a named covariance function. Two
% modes are possible: training and prediction: if no test data are given, the
% function returns minus the log likelihood and its partial derivatives with
% respect to the hyperparameters; this mode is used to fit the hyperparameters.
% If test data are given, then (marginal) Gaussian predictions are computed,
% whose mean and variance are returned. Note that in cases where the covariance
% function has noise contributions, the variance returned in S2 is for noisy
% test targets; if you want the variance of the noise-free latent function, you
% must substract the noise variance.
% Modified by Frank Hutter (FH) to enable censoring.
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
% FH: cens   is a (column) vector (of size n) indicating whether a data
% point was left-censored. If cens(i)==1 then y(i) is only a lower
% bound on the response.
% This follows "Gaussian Process Models for Censored Sensor Readings" by
% Emre Ertin, 2007 IEEE 665-669.
% y here means t in that paper; f here means y there.
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
%=== Check if there is any noise.
if length(covfunc) ~= 2 | ~strcmp(covfunc(1), 'covSum') | ~strcmp(covfunc{2}(end), 'covNoise')
    sigma_n = sqrt(exp(2*logtheta(end)));           % sqrt(noise variance)
    K_nonoise = K - sigma_n*sigma_n*eye(size(K,1));
else
    K_nonoise = K;
    sigma_n = 1e-10; % min_noise
end
tmp = max(max(max(K_nonoise)),1e-10);
K_nonoise = K_nonoise + tmp/1e10*eye(n); %FH: min_noise for numerical stability

L_nonoise = chol(K_nonoise)';                        % cholesky factorization of the covariance
invL_nonoise = L_nonoise\eye(n);
invK_nonoise = L_nonoise'\invL_nonoise;

% invR = L'\eye(n);
% %invK = L'\(L\eye(n));
% invL = L\eye(n);
% invK = invR*invL;

%FH: Find f_bar, i.e. the most likely f_{1:N} given y_{1:N} and cens_{1:N}
cens_idx = find(cens==1);
noncens_idx = find(cens==0);

%=== Gradient optimizer to find best f_bar; initialize with y.
options.Method = 'lbfgs';
%options.iterations = 100;
%options.numDiff = 1; % until I have implemented the gradient.
options.Display = 'off';
warning off MATLAB:nearlySingularMatrix;
%options.DerivativeCheck = 'on';

% TODO: only optimize f_bar for the censored data points - use a
% conditional Gaussian for them given the uncensored points => lower
% dimensionality for the numerical optimization problem.
funcToOptimize = @(f) negLogCensoredConditional(f, y, cens, invL_nonoise, invK_nonoise, sigma_n);
f_bar = minFunc(funcToOptimize, y, options);

%=== Assert that the approximation is perfect in the absence of censoring.
% if ~any(cens)
%     assert(f_bar < y+0.1); 
%     assert(f_bar > y-0.1); 
% end
%=== FH censoring end.
alpha_nonoise = solve_chol(L_nonoise',f_bar); % More efficient for: alpha=inv(K_nonoise)*f_bar

if nargin == 5 % if no test cases, compute the negative log marginal likelihood
    error('')
%   %=== Contribution of uncensored data.
%   out1 = 0.5*f_bar(noncens_idx)'*alpha(noncens_idx) + sum(log(diag(L(noncens_idx,noncens_idx)))) + 0.5*length(noncens_idx)*log(2*pi); %page 19 in the GP book
%   
%   %=== Contribution of censored data: probability of censoring given the predicted Gaussian at each observation point x.
%   [meanCens, varCens] = mypredict(logtheta, covfunc, x, x(cens_idx,:), L, alpha, n, noncens_idx, cens_idx, y, f_bar, sigma_n);
%   for i=1:length(cens_idx)
%       %=== If the censoring threshold y(cens_idx(i)) is high, then the
%       %=== probability of being censored is low.
%       % minus b/c we want *negative* log marginal likelihood
%       out1 = out1 - (normcdfln( (meanCens(i)-y(cens_idx(i)))/sqrt(varCens(i)) ));
%   end
% 
%   if nargout == 2               % ... and if requested, its partial derivatives
%       error 'Will do the derivative later ...'
%     out2 = zeros(size(logtheta));       % set the size of the derivative vector
%     W = L'\(L\eye(n))-alpha*alpha';                % precompute for convenience
%     for i = 1:length(out2)
%       out2(i) = sum(sum(W.*feval(covfunc{:}, logtheta, x, i)))/2;
%     end
%   end
% 
else                    % ... otherwise compute (marginal) test predictions ...
    [Kss, Kstar] = feval(covfunc{:}, logtheta, x, xstar);     %  test covariances (Kss already includes noise term on the diagonal)
    out1 = Kstar' * alpha_nonoise;                                      % predicted means -- FH: alpha=inv(K)*f_bar

    if nargout == 2
        %=== Contribution of the regular GP equations k_{**} - k_*^T
        %[K+\sigma I]
        v = L_nonoise\Kstar; %FH: Kstar is N by N, with Kstar(:,m)= k_m for query data point m.
        %                 v is inv(L_nonoise)*Kstar, such that v.*v is Kstar' * inv(K_nonoise) * Kstar
        %                 Then sum(v.*v)' is an N by 1 vector a with a(m) = k_m
        %                 for query data point m.
        %                 K is C_m in the notation of the censoring paper.
        out2 = Kss - sum(v.*v)';

        % Hessian of Normal is the negative precision matrix
        diag_add = zeros(n,1);
        diag_add(noncens_idx) = -1/sigma_n^2;
        if ~isempty(cens_idx)
            normed_diff = (f_bar(cens_idx)-y(cens_idx))/sigma_n;

            %=== To avoid numerical problems: log(a+b) trick
            pos_idx = find(normed_diff>0);
            same_idx = find(normed_diff==0);
            neg_idx = find(normed_diff<0);
            log_A_plus_B = zeros(length(cens_idx),1);
            logB = 2*normpdfln(normed_diff')';

            %=== pos_idx
            logA = log(f_bar(cens_idx(pos_idx))-y(cens_idx(pos_idx))) + log(1/sigma_n) + normcdfln(normed_diff(pos_idx)')' + normpdfln(normed_diff(pos_idx)')';
            log_A_plus_B(pos_idx) = log_sum_exp(logA, logB(pos_idx));

            %=== neg_idx
            logA = log(-f_bar(cens_idx(neg_idx))+y(cens_idx(neg_idx))) + log(1/sigma_n) + normcdfln(normed_diff(neg_idx)')' + normpdfln(normed_diff(neg_idx)')';
            log_A_plus_B(neg_idx) = log_diff_exp(logB(neg_idx),logA);

            %=== same_idx 
            log_A_plus_B(same_idx) = logB(same_idx);

            log_add = log_A_plus_B - 2*normcdfln(normed_diff')';
            diag_add(cens_idx) = -1/sigma_n^2 * exp(log_add);
        end

        H = -(-invK_nonoise + diag(diag_add));

        %    T = chol(H)';                        % cholesky factorization of the Hessian
        a=Kstar'*invK_nonoise;
        cens_contrib = diag(a*inv(H)*a');
        out2 = out2 + cens_contrib;
    %    out2 = out2 + diag(Kstar'*invK*inv(H)*invK*Kstar);
        assert(all(out2>=0));
        assert(all(imag(out2)==0));
    end
end
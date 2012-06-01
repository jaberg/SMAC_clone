function [K, L, invL, alpha, nlml, dnlml, dKs] = gprPrepare(logtheta, covfunc, X, y)

% gprPrepare: performs all precomputation possible without test data,
% and, if asked for, returns minus the log likelihood and 
% its partial derivatives with respect to the hyperparameters; 
% this can be used to fit the hyperparameters.
% The returned matrices and vectors are all based on a covariance matrix
% K that already has the observation noise added to the diagonal.
%
% usage: [K, L, invL, alpha, nlml dnlml] = prepareModel(model)
%
% where
%   logtheta is a (column) vector of log hyperparameters
%   covfunc  is the covariance function
%   X        is a n by D matrix of training inputs
%   y        is a (column) vector (of size n) of targets

if ischar(covfunc), covfunc = cellstr(covfunc); end % convert to cell if needed
[n, D] = size(X);
if eval(feval(covfunc{:})) ~= size(logtheta, 1)
    error('Error: Number of parameters do not agree with covariance function')
end

K = feval(covfunc{:}, logtheta, X);    % compute training set covariance matrix
K = K + max(1e-8, max(max(K))/1e8)*eye(length(K)); %FH: min_noise for numerical stability

L = chol(K)';                        % cholesky factorization of the covariance
alpha = solve_chol(L',y);
invL = L\eye(n);

if nargout > 4 % compute the negative log marginal likelihood
    nlml = 0.5*y'*alpha + sum(log(diag(L))) + 0.5*n*log(2*pi);

    if nargout >= 6                 % ... and if requested, its partial derivatives
        dnlml = zeros(size(logtheta));      % set the size of the derivative vector
        W = L'\(L\eye(n))-alpha*alpha';                % precompute for convenience
        
        if nargout >=7
            %=== Cache derivatives of kernel for outside.
            dKs = cell(length(logtheta),1);
            for i = 1:length(dnlml)
                dKs{i} = feval(covfunc{:}, logtheta, X, i);
                dnlml(i) = sum(sum(W.*dKs{i}))/2;
            end
        else
            %=== Normal.
            for i = 1:length(dnlml)
                dnlml(i) = sum(sum(W.*feval(covfunc{:}, logtheta, X, i)))/2;
            end
        end
    end
end
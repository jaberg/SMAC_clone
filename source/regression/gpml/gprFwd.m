function [mu, S2, Kss_joint] = gprFwd(X, L, invL, alpha, covfunc, logtheta, Xstar, observationNoise, joint);
% gprFwd - prediction: (marginal) Gaussian predictions are computed,
% whose mean and variance are returned. Note that in cases where the covariance
% function has noise contributions, the variance returned in S2 is for noisy
% test targets; if you want the variance of the noise-free latent function, you
% must substract the noise variance.
%
% usage: [mu S2]  = gprFwd(X, L, invL, alpha, covfunc, logtheta, Xstar)
%
% where:
%
%   X        is a n by D matrix of training inputs
%   L        is a D by D lower triangular matrix, the lower triangular
%            cholesky factor of the covariance matrix K at the training 
%            inputs X; L*L'=K
%   invL     is a D by D upper triangular matrix with invL = inv(L)
%   alpha    is a (column) vector (of size n) with alpha=inv(K)*y  
%            (it was computed efficiently as solve_chol(L',y));
%   covfunc  is the covariance function
%   logtheta is a (column) vector of log hyperparameters
%   Xstar    is a nn by D matrix of test inputs
%   joint    is an optional scalar that, if > 0 indicates that we want the
%            full prediced covariance matrix of the joint output
%
%   mu       is a (column) vector (of size nn) of prediced means
%   S2       is a (column) vector (of size nn) of predicted variances if
%            joint == 0, and 
%            is a nn by nn matrix of predicted covariances if joint ~= 0
%
% Note that L and alpha are based on a K that already includes a diagonal
% noise term, so strictly it's [K + \sigma_n^2 * I]
% Kss below also includes that diagonal noise term, so the predictive 
% variance already includes noise.

if observationNoise & joint
    warning 'Joint prediction wont have observation noise'; %'Should not ask for the joint prediction with observation noise included.'
end
if nargout == 3 & ~joint
    error 'Can only ask for the joint Kss when asking for the joint prediction'
end

[Kss, Kstar] = feval(covfunc{:}, logtheta, X, Xstar);   % Kss includes noise on diag, Kstart does not (not even diagonal)
mu = Kstar' * alpha;                                    % predicted means

if nargout >= 2
%    v = L\Kstar;
    v = invL * Kstar;
        %FH: Kstar is n by nn, with Kstar(i,j) giving the correlation 
        %                      betwen ith training and jth test point.
        %    v is inv(L)*Kstar, such that v.*v is Kstar' * inv(K) * Kstar
        %    Then sum(v.*v)' is an nn by 1 vector
        
    if joint > 0 % get the full joint covariance
%         K11 = gpcovarp(model.net, X, X);
%         K12 = gpcovarp(model.net, X, model.X);
%            model.net.Kprior = gpcovar(model.net, model.X);
%            model.net.invPrior = inv(model.net.Kprior);
%            model.net.weight = model.net.invPrior * model.y;
%         % Prediction
%         yPred = K12*model.net.weight;  
%         % Covariance
%         Ycov = K11-K12*model.net.invPrior*K12';
%         yPredVar = Ycov;
%         Kss_joint = K11;
        
        [Kss_diag, Kss_joint] = feval(covfunc{:}, logtheta, Xstar, Xstar);  % test covariances, in the joint without noise component
        
%         Kss_joint_noisy = feval(covfunc{:}, logtheta, Xstar);  % joint test covariances, with noise component
%         noise_diag = feval('covNoise', logtheta(end), Xstar);
%         tmp = Kss_joint_noisy - noise_diag; %exactly the same as Kss_joint
        
        if observationNoise
            Kss_joint_plus_noise_on_diag = Kss_joint + diag(-diag(Kss_joint) + Kss_diag);
            S2 = Kss_joint_plus_noise_on_diag - v'*v;       % predicted covariances with observation noise on diag
        else
            S2 = Kss_joint - v'*v;                          % predicted covariances without observation noise
        end
        
%        [tmp, K12] = feval(covfunc{:}, logtheta, Xstar, X);
%        tmp = Kss_joint - K12 * inv(L*L') * K12';
%        S2 = tmp;
        
    else
        S2 = Kss - sum(v.*v)';                              % predicted variances, with observation noise
        if ~observationNoise
            %=== We check that the covfunc cell array is a covSum, with last entry 'covNoise'
            if length(covfunc) == 2 & strcmp(covfunc(1), 'covSum') & strcmp(covfunc{2}(end), 'covNoise')
                S2_obs = exp(2*logtheta(end));              % noise variance
                S2 = S2 - S2_obs;                           % predicted variances, without observation noise
            end
        end
    end
end
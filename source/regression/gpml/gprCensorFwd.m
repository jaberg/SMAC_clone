function [mu, S2, Kss_joint] = gprCensorFwd(X, L_nonoise, alpha_nonoise, CombRoot, covfunc, logtheta, Xstar, observationNoise, joint);

% gprCensorFwd - prediction: (marginal) Gaussian predictions are computed,
% whose mean and variance are returned. Note that in cases where the covariance
% function has noise contributions, the variance returned in S2 is for noisy
% test targets; if you want the variance of the noise-free latent function, you
% must substract the noise variance.
%
% usage: [mu S2]  = gprCensorFwd(X, L_nonoise, invL_nonoise, alpha_nonoise, covfunc, logtheta, Xstar)
%
% where:
%
%   X               is a n by D matrix of training inputs
%   L_nonoise       is a D by D lower triangular matrix, the lower triangular
%                   cholesky factor of the covariance matrix K at the training 
%                   inputs x; L*L'=K
%   invL_nonoise    is a D by D upper triangular matrix with invL = inv(L)
%   alpha_nonoise   is a (column) vector (of size n) with alpha=inv(K)*y  
%                   (it was computed efficiently as solve_chol(L',y));
%   covfunc         is the covariance function
%   logtheta        is a (column) vector of log hyperparameters
%   Xstar           is a nn by D matrix of test inputs
%
%   mu              is a (column) vector (of size nn) of prediced means
%   S2              is a (column) vector (of size nn) of predicted variances
%
% Note that L and alpha are based on a K that already includes a diagonal
% noise term, so strictly it's [K + \sigma_n^2 * I]
% Kss below also includes that noise term, so the predictive 
% variance already includes noise.

if observationNoise & joint
    error 'Shouldnt ask for the joint prediction with observation noise included.'
end
if nargout == 3 & ~joint
    error 'Can only ask for the joint Kss when asking for the joint prediction'
end

[Kss, Kstar] = feval(covfunc{:}, logtheta, X, Xstar);     %  test covariances (Kss already includes noise term)
mu = Kstar' * alpha_nonoise;                              % predicted means -- FH: alpha_nonoise=inv(K_nonoise)*f_bar

if nargout >= 2
    %=== First and second part: k_{**} - k_*^\top K^{-1} k_*
    v = L_nonoise\Kstar;    %FH: Kstar is n by nn, with Kstar(i,j) giving the correlation 
                            %    betwen ith training and jth test point.
                            %    v is inv(L_nonoise)*Kstar, such that 
                            %    v.*v is Kstar' * inv(K_nonoise) * Kstar
                            %    Then sum(v.*v)' is an nn by 1 vector
                            
    %=== Third part: add k_*^\top K^{-1} H^{-1} K k_*
    %    Slower version: S2 = S2 + diag(Kstar' * invK_times_invH_times_invK * Kstar);

    w = CombRoot * Kstar;
    if joint > 0 % get the full joint covariance
        [Kss_diag, Kss_joint] = feval(covfunc{:}, logtheta, Xstar, Xstar);  % test covariances, in the joint without noise component
        S2 = Kss_joint - v'*v + w'*w;                                       % predicted covariances without observation noise
    else
        S2 = Kss - sum(v.*v)' + sum(w.*w)';
        
        if ~observationNoise
            %=== We check that the covfunc cell array is a covSum, with last entry 'covNoise'
            if length(covfunc) == 2 & strcmp(covfunc(1), 'covSum') & strcmp(covfunc{2}(end), 'covNoise')
                S2_obs = exp(2*logtheta(end));                                % noise variance
                S2 = S2 - S2_obs;                           % predicted variances, with observation noise
            end
        end

        assert(all(S2>=0));
        assert(all(imag(S2)==0));
    end
end
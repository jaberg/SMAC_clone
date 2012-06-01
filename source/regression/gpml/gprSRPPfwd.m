function [mu, S2SR, S2PP] = gprSRPPfwd(Kmm, invKmm, saved_1, saved_2, logtheta, covfunc, INDEX, x, xstar, observationNoise);

% gprSRPP - Carries out approximate Gaussian process regression prediction
% using the subset of regressors (SR) or projected process approximation (PP)
% and the active set specified by INDEX.
%
% Usage
%
%   [mu, S2SR, S2PP] = gprSRPP(logtheta, covfunc, x, INDEX, y, xstar)
%
% where
%
%   logtheta is a (column) vector of log hyperparameters
%   covfunc  is the covariance function, which is assumed to
%            be a covSum, and the last entry of the sum is covNoise
%   x        is a n by D matrix of training inputs
%   INDEX    is a vector of length m <= n used to specify which 
%            inputs are used in the active set 
%   y        is a (column) vector (of size n) of targets
%   xstar    is a nstar by D matrix of test inputs
%   mu       is a (column) vector (of size nstar) of prediced means
%   S2SR  is a (column) vector (of size nstar) of predicted variances under SR
%   S2PP  is a (column) vector (of size nsstar) of predicted variances under PP
%
% where D is the dimension of the input.
%
% For more help on covariance functions, see "help covFunctions".
%
% (C) copyright 2005, 2006 by Chris Williams (2006-03-29).


% we check that the covfunc cell array is a covSum, with last entry
% 'covNoise'
%if length(covfunc) ~= 2 | ...
%        ~strcmp(covfunc(1), 'covSum') |...
%        ~strcmp(covfunc{2}(end), 'covNoise')
%  error('The covfunc must be "covSum" whose last summand must be "covNoise"')
%end

sigma2n = exp(2*logtheta(end));                                % noise variance

% a is cov between active set and test points and vstar is variances at test
% points, incl noise variance
[vstar, a] = feval(covfunc{:}, logtheta, x(INDEX,:), xstar);   

mu = a'*saved_1;  % pred mean eq. (8.14) and (8.26)

% e =  saved_2 \ a; % old meaning of saved_2
e =  saved_2 * a;

S2SR = sigma2n*sum(a.*e,1)';                 % noise-free SR variance, eq. 8.15
%S2PP = vstar-sum(a.*(Kmm\a),1)'+S2SR;  % PP variance eq. (8.27) including noise
S2PP = vstar-sum(a.*(invKmm*a),1)'+S2SR;  % PP variance eq. (8.27) including noise
S2SR = S2SR + sigma2n;                            % SR variance inclusing noise

if ~observationNoise
    S2PP = S2PP - sigma2n;
    S2SR = S2SR - sigma2n;
end
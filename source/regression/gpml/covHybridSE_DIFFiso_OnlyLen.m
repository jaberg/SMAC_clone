function [A, B] = covHybridSE_DIFFiso_OnlyLen(logtheta, x, z);
% Covariance function that is composed of a squared exponential for
% continuous parameters and a weighted hamming distance exponential for
% categorical parameters. Both do *not* use ARD.
%
% The hyperparameters are:
%
% loghyper = [ log(ell) ]

if nargin == 0, A = '1'; return; end              % report number of parameters
global gprParams;

assert(max(max(mod(x(:,gprParams.combinedcat), 1)))==0);
assert(min(min(mod(x(:,gprParams.combinedcont), 1)))>0);
assert(length(gprParams.combinedcat) + length(gprParams.combinedcont) == size(x,2));

if nargin > 2 && nargout == 2
    assert(max(max(mod(z(:,gprParams.combinedcat), 1)))==0);
    assert(min(min(mod(z(:,gprParams.combinedcont), 1)))>0);
    assert(length(gprParams.combinedcat) + length(gprParams.combinedcont) == size(z,2));
end

persistent K;
[n D] = size(x);
scalarEll = exp(logtheta(1));
ell = scalarEll * ones(D,1); % characteristic length scale, same for all
sf2 = 1;

if nargin == 2
    exponent_cont = 0;
    if ~isempty(gprParams.combinedcont)
        exponent_cont = -sq_dist(x(:,gprParams.combinedcont)'/scalarEll)/2;
    end
    exponent_cat = 0;
    if ~isempty(gprParams.combinedcat)
        exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'),[],ell(gprParams.combinedcat))/2;
    end
    K = sf2*exp(exponent_cont + exponent_cat);
    A = K;
elseif nargout == 2                              % compute test set covariances
    A = sf2*ones(size(z,1),1);
    exponent_cont = 0;
    if ~isempty(gprParams.combinedcont)
        exponent_cont = -sq_dist(x(:,gprParams.combinedcont)'/scalarEll, z(:,gprParams.combinedcont)'/scalarEll)/2;
    end
    exponent_cat = 0;
    if ~isempty(gprParams.combinedcat)
        exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'), int32(z(:,gprParams.combinedcat)'), ell(gprParams.combinedcat))/2;
    end
    B = sf2*exp(exponent_cont + exponent_cat);
else                                                % compute derivative matrix
    if z == 1                                                   % first parameter
        exponent_cont = 0;
        if ~isempty(gprParams.combinedcont)
            exponent_cont = -sq_dist(x(:,gprParams.combinedcont)'/scalarEll)/2;
        end
        exponent_cat = 0;
        if ~isempty(gprParams.combinedcat)
            exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'), [], ell(gprParams.combinedcat))/2;
        end
        A = 2*sf2*exp(exponent_cont + exponent_cat);
    else
        error 'Only has one parameter, ell.'
    end
end
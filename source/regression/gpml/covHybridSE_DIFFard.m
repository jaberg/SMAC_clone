function [A, B] = covHybridSE_DIFFard(logtheta, x, z)
% Covariance function that is composed of a squared exponential for
% continuous parameters and a weighted hamming distance exponential for
% categorical parameters. Both use ARD.
%
% The hyperparameters are:
%
% logtheta = [ log(ell_1)
%              log(ell_2)
%               .
%              log(ell_D)
%              log(sqrt(sf2)) ]

if nargin == 0, A = '(D+1)'; return; end          % report number of parameters
global gprParams;

persistent K;
[n D] = size(x);
ell = exp(logtheta(1:D));                         % characteristic length scale
sf2 = exp(2*logtheta(D+1));                                   % signal variance

if nargin == 2
    exponent_cont = 0;
    if ~isempty(gprParams.combinedcont)
        exponent_cont = -sq_dist(diag(1./ell(gprParams.combinedcont))*x(:,gprParams.combinedcont)')/2;
    end
    exponent_cat = 0;
    if ~isempty(gprParams.combinedcat)
        exponent_cat =  -w_ham_dist(int32(x(:,gprParams.combinedcat)'),[],ell(gprParams.combinedcat))/2;
    end
    K = sf2*exp(exponent_cont + exponent_cat);
    A = K;
elseif nargout == 2                              % compute test set covariances
    A = sf2*ones(size(z,1),1);
    exponent_cont = 0;
    if ~isempty(gprParams.combinedcont)
        exponent_cont = -sq_dist(diag(1./ell(gprParams.combinedcont))*x(:,gprParams.combinedcont)',diag(1./ell(gprParams.combinedcont))*z(:,gprParams.combinedcont)')/2;
    end

    exponent_cat = 0;
    if ~isempty(gprParams.combinedcat)
        exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'),int32(z(:,gprParams.combinedcat)'),ell(gprParams.combinedcat))/2;
    end
    B = sf2*exp(exponent_cont + exponent_cat);
else                                                % compute derivative matrix
    % check for correct dimension of the previously calculated kernel matrix
    if any(size(K)~=n)  
        K = sf2*exp(-sq_dist(diag(1./ell)*x')/2);
    end

    if z <= D                                           % length scale parameters
        if ismember(z, gprParams.combinedcont)
            A = K.*sq_dist(x(:,z)'/ell(z));
        else
            A = K.*w_ham_dist(int32(x(:,z)'),[],ell(z));
        end
    else                                                    % magnitude parameter
        A = 2*K;
        clear K;
    end
end
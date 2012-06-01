function [A, B] = covHybridSE_DIFFiso_algo(logtheta, x, z);
% Covariance function that is composed of a squared exponential for
% continuous parameters and a weighted hamming distance exponential for
% categorical parameters. Both do *not* use ARD.
%
% The hyperparameters are:
%
% loghyper = [ log(ell_features)
%              log(ell_algoparams)
%              log(sqrt(sf2)) ]

if nargin == 0, A = '3'; return; end              % report number of parameters
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
scalarEllForAlgoParams = exp(logtheta(2));

instParam = setdiff(1:D, gprParams.algoParam);
ell = -ones(D,1);
ell(instParam) = scalarEll;
ell(gprParams.algoParam) = scalarEllForAlgoParams;
%ell = scalarEll * ones(D,1); % characteristic length scale, same for all
sf2 = exp(2*logtheta(3));                                     % signal variance

if nargin == 2
    exponent_cont = 0;
    if ~isempty(gprParams.combinedcont)
        exponent_cont = -sq_dist(diag(1./ell(gprParams.combinedcont))*x(:,gprParams.combinedcont)')/2;
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
        exponent_cont = -sq_dist(diag(1./ell(gprParams.combinedcont))*x(:,gprParams.combinedcont)',diag(1./ell(gprParams.combinedcont))*z(:,gprParams.combinedcont)')/2;
    end
    exponent_cat = 0;
    if ~isempty(gprParams.combinedcat)
        exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'), int32(z(:,gprParams.combinedcat)'), ell(gprParams.combinedcat))/2;
    end
    B = sf2*exp(exponent_cont + exponent_cat);
else                                                % compute derivative matrix
%    if z <= D                                           % length scale parameters
%        if ismember(z, cont_vars)
%            A = K.*sq_dist(x(:,z)'/ell(z));
%        else
%            A = K.*w_ham_dist(int32(x(:,z)'),[],ell(z));
%        end
    if z == 1                                                   % first parameter: length scale for instance features
        exponent_cont = 0;
        if ~isempty(gprParams.combinedcont)
            cont_inst_param = intersect(gprParams.combinedcont, instParam);
            exponent_cont = -sq_dist(diag(1./ell(cont_inst_param))*x(:,cont_inst_param)')/2;
        end
        exponent_cat = 0;
        if ~isempty(gprParams.combinedcat)
            cat_inst_param = intersect(gprParams.combinedcat, instParam)
            exponent_cat = -w_ham_dist(int32(x(:,cat_inst_param)'), [], ell(cat_inst_param))/2;
        end
        A = sf2*exp(exponent_cont + exponent_cat) .* (-2*(exponent_cont + exponent_cat));
    elseif z == 2                                               % second parameter: length scale for algorithm parameters
        exponent_cont = 0;  
        if ~isempty(gprParams.combinedcont)
            cont_algo_param = intersect(gprParams.combinedcont, gprParams.algoParam);
            exponent_cont = -sq_dist(diag(1./ell(cont_algo_param))*x(:,cont_algo_param)')/2;
        end
        exponent_cat = 0;
        if ~isempty(gprParams.combinedcat)
            cat_algo_param = intersect(gprParams.combinedcat, gprParams.algoParam)
            exponent_cat = -w_ham_dist(int32(x(:,cat_algo_param)'), [], ell(cat_algo_param))/2;
        end
        A = sf2*exp(exponent_cont + exponent_cat) .* (-2*(exponent_cont + exponent_cat));
    else                                                        % third parameter
        exponent_cont = 0;
        if ~isempty(gprParams.combinedcont)
            exponent_cont = -sq_dist(diag(1./ell(gprParams.combinedcont))*x(:,gprParams.combinedcont)')/2;
        end
        exponent_cat = 0;
        if ~isempty(gprParams.combinedcat)
            exponent_cat = -w_ham_dist(int32(x(:,gprParams.combinedcat)'), [], ell(gprParams.combinedcat))/2;
        end
        A = 2*sf2*exp(exponent_cont + exponent_cat);
    end
end
function [A, B] = covDIFFard(logtheta, x, z);

% Difference covariance function by Frank Hutter with Automatic Relevance 
% Detemination (ARD) distance measure.
% The covariance function is parameterized as:
%
% k(x^p,x^q) = sf2 * exp(-r'*inv(P)*r) where r = 1 if x^p==x^q and 0 o/w
%
% where the P matrix is diagonal with ARD parameters ell_1^2,...,ell_D^2, where
% D is the dimension of the input space and sf2 is the signal variance. The
% hyperparameters are:
%
% logtheta = [ log(ell_1)
%              log(ell_2)
%               .
%              log(ell_D)
%              log(sqrt(sf2)) ]

if nargin == 0, A = '(D+1)'; return; end          % report number of parameters

persistent K;                 
[n D] = size(x);
ell = exp(logtheta(1:D));                         % characteristic length scale
sf2 = exp(2*logtheta(D+1));                                   % signal variance

if nargin == 2
  K = sf2*exp(-w_ham_dist(int32(x'),[],ell)/2);
  A = K;                 
elseif nargout == 2                              % compute test set covariances
  A = sf2*ones(size(z,1),1);
  B = sf2*exp(-w_ham_dist(int32(x'),int32(z'),ell)/2);
else                                                % compute derivative matrix
  if z <= D                                           % length scale parameters
    A = K.*w_ham_dist(int32(x(:,z)'),[],ell(z));  
  else                                                    % magnitude parameter
    A = 2*K;
    clear K;
  end
end
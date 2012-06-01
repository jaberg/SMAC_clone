function [A, B] = covDIFFiso(logtheta, x, z);

% Simple difference covariance function by Frank Hutter with isotropic 
% distance measure. The covariance function is parameterized as:
%
% k(x^p,x^q) = sf2 * exp(-(r)'*inv(P)*(r) where r = min(|x^p-x^q|,1) 
%
% where the P matrix is ell^2 times the unit matrix and sf2 is the signal
% variance. The hyperparameters are:
%
% logtheta = [ log(ell)
%              log(sqrt(sf2)) ]

if nargin == 0, A = '2'; return; end              % report number of parameters

[n D] = size(x);
ell = exp(logtheta(1));                           % characteristic length scale
sf2 = exp(2*logtheta(2));                                     % signal variance

if nargin == 2
  A = sf2*exp(-diff_dist(x',[],0)/(2*ell*ell));
  
elseif nargout == 2                              % compute test set covariances
  A = sf2*ones(size(z,1),1);
  B = sf2*exp(-diff_dist(x',z',0)/(2*ell*ell));
else                                                % compute derivative matrix
  if z == 1                                                   % first parameter
    A = sf2*exp(-diff_dist(x',[],0)/(2*ell*ell)).*diff_dist(x',[],0)/(ell*ell);  
  else                                                       % second parameter
    A = 2*sf2*exp(-diff_dist(x',[],0)/(2*ell*ell));
  end
end


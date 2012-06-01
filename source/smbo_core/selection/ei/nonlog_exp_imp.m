function expected_improvement = nonlog_exp_imp(f_min, mu, sigma)
%sigma(find(sigma<1e-10)) = NaN; % To avoid division by zero.
% Tom Minka's normpdf takes row vectors -- column vectors are interpreted as multivariate.
expected_improvement = (f_min-mu) .* normcdf((f_min-mu)./sigma) + sigma .* normpdf(((f_min-mu)./sigma)')';

% Maybe not the most robust and exactly zero often, but fast.
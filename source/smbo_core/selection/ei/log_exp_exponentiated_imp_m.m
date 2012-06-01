function log_expected_exponentiated_improvement = log_exp_exponentiated_imp_m(f_min, mu, sigma)
% Get expected improvement, where f_min is the best *logarithmic* objective 
% function value found so far, and mu and sigma specify our Gaussian
% prediction of the *logarithmic* objective function value at a new point.
 
b=exp(f_min);

%Actual formula, but numerical problems:
%expected_exponentiated_improvement = b*normcdf((f_min-mu)./sigma) - exp(sigma.^2/2 + mu).*normcdf((f_min-mu)./sigma - sigma);

%More robust version of the above: 
expected_exponentiated_improvement = exp(f_min + normcdfln((f_min-mu)./sigma)) - exp(sigma.^2/2 + mu + normcdfln((f_min-mu)./sigma - sigma));

%Even the more robust version can still yield infty-infty, so work in the
%log space until the end -- but this is very slow :-(
log_expected_exponentiated_improvement = zeros(length(mu),1);
for i=1:length(mu)
    c = f_min + normcdfln((f_min-mu(i))/sigma(i));
    %=== log(y-z) is tricky, we distinguish two cases based on z<0 or z>0:
%     if (sigma(i)^2/4 + mu(i)) < 0
%         % When y>0, z<0, we define c=ln(y), d=ln(-z).
%         % Then y-z = exp[ max(c,d) + ln(1 + exp(-|d-c|)) ],
%         % and thus log(y-z) = max(c,d) + ln(1 + exp(-|d-c|))
%         d = log(-(sigma(i)^2/4 + mu(i))) + normcdfln((f_min-mu(i))/sigma(i) - sigma(i)/2);
%         log_expected_exponentiated_improvement(i) = max(c,d) + log(1 + exp(-abs(d-c)));
%         assert(imag(log_expected_exponentiated_improvement(i))==0);
%         assert(exp(log_expected_exponentiated_improvement(i)) > expected_exponentiated_improvement(i)-1e-3);
%         assert(exp(log_expected_exponentiated_improvement(i)) < expected_exponentiated_improvement(i)+1e-3);
%     else

        % When y>0, z>0, we define c=ln(y), d=ln(z), and it has to be true that d <= c in order to satisfy y-z>=0.
        % Then y-z = exp[ c + ln(exp(c-d) -1) ],
        % and thus log(y+z) = d + ln(exp(c-d) -1)
        d = (sigma(i)^2/2 + mu(i)) + normcdfln((f_min-mu(i))/sigma(i) - sigma(i));
        if c<=d
            error ''
            %=== This can happen due to approx. errors with normcdf.
            log_expected_exponentiated_improvement(i) = -inf;
        else
            log_expected_exponentiated_improvement(i) = d + log(exp(c-d)-1);
        end
        assert(imag(log_expected_exponentiated_improvement(i))==0);
        itisnan = isnan(expected_exponentiated_improvement(i));
        same_above = (exp(log_expected_exponentiated_improvement(i)) > expected_exponentiated_improvement(i)-1e-3);
        same_below = (exp(log_expected_exponentiated_improvement(i)) < expected_exponentiated_improvement(i)+1e-3);
        assert(itisnan | (same_above & same_below))
%    end
end
log_expected_exponentiated_improvement(find(log_expected_exponentiated_improvement==-inf)) = -1e100;
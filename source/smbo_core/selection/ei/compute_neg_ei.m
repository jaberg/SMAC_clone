function neg_ei = compute_neg_ei(f_min_samples, predmean, predvar, expImpCriterion)
assert(length(f_min_samples)==1);

N = length(predmean);
neg_ei = zeros(N,1);

log_of_10 = log(10);
for j=1:length(f_min_samples)
    expImp = zeros(N,1);
    f_min = f_min_samples(j);
    
    switch expImpCriterion
        case 0 % 'eEI'
            %=== Our Gaussian fit N(mu, sig^2) is on log10(y); so ln(y) is
            %=== distributed according to N(log(10) mu, log(10)^2 sig^2).
            %=== f_min is also based on log10, so to get it to ln mult by log_of_10
            %expImp = exp(log_exp_exponentiated_imp(log_of_10*f_min, log_of_10*predmean, log_of_10*sqrt(predvar)))'; % variance is log_of_10^2 times var
            
            % not taking the exp to not lose the differences between very
            % small EIs
            expImp = log_exp_exponentiated_imp(log_of_10*f_min, log_of_10*predmean, log_of_10*sqrt(predvar))'; % variance is log_of_10^2 times var

        case 1 % 'EI2'
            %=== Slow, original, SPO implementation
    %                         for k=1:length(nz_idx)
    %                             i = nz_idx(k);
    %                             ui = (f_min - predmean(i) )/sqrt(predvar(i));
    %                             expImp2(i) = predvar(i) * ((ui*ui+1) * normcdf(ui) + ui*normpdf(ui)); %default: E(I^2) in (3.5) [Schon98b]
    %                         end

            %=== Fast, vectorized implementation with identical
            %=== behaviour; note the (uis')' for normpdf;
            %=== that's such that lightspeed does not interpret it
            %=== as a multivariate Gaussian
            uis = (f_min - predmean)./sqrt(predvar);
            expImp = predvar .* ((uis.*uis+1) .* normcdf(uis) + uis.*(normpdf(uis')')); %default: E(I^2) in (3.5) [Schon98b]

    %                         assertVectorEq(expImp(:), expImp2(:));

        case {3,4} % {'EI', 'EIh'}            
%             log_expected_improvement = log_exp_imp(f_min, predmean, sqrt(predvar));
%             expImp = exp(log_expected_improvement);
            expImp = nonlog_exp_imp(f_min, predmean, sqrt(predvar));
            expImp = expImp(:);

            if expImpCriterion == 4 % strcmp(al_opts.expImpCriterion, 'EIh')
                if ~isempty(strfind(model.type, 'GP'))
                    sigma_sqr_e = exp(2*model.params(end));
                elseif strfind(model.type, 'kriging')
                    sigma_sqr_e = (1-model.g) * model.var;
                else
                    error 'Augmented EI criterion by Huang et al only applies to noise GPs' 
                end
                expImp = expImp .* (1- (sqrt(sigma_sqr_e) ./ sqrt(predvar + sigma_sqr_e)));
            end            
            
        case 5 % trivial, just e^mean to guarantee it's positive
            expImp = exp(-predmean);
        case 6 % 'EI2 with sqrt(var)'
            uis = (f_min - predmean)./(predvar.^(0.25));
            expImp = predvar .* ((uis.*uis+1) .* normcdf(uis) + uis.*(normpdf(uis')')); %default: E(I^2) in (3.5) [Schon98b]
        case 7 
            expImp = -predmean +(predvar.^0.5);
        otherwise
            error(strcat('Unknown exp. imp. criteration al_opts.expImpCriterion: ', al_opts.expImpCriterion));
    end
    neg_ei = neg_ei - expImp(:)/length(f_min_samples);                
end
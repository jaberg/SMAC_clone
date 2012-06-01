function [neg_ei, predmean, predvar] = neg_ei_of_model(Theta, model, expImpCriterion, f_min_samples)

[predmean, predvar] = applyMarginalModel(model, Theta, [], 0, 0);

neg_ei = compute_neg_ei(f_min_samples, predmean, predvar, expImpCriterion);
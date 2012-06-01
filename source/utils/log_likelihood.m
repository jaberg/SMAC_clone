function ll = log_likelihood(y,yPredMean,yPredVar,cens,weights)
if nargin < 5
    weights = 1/length(y) * ones(length(y),1);
end
cens_idx=find(cens==1);
uncens_idx=find(cens==0);
invYPredStd = 1./sqrt(yPredVar);
ll = sum(weights(uncens_idx) .* (normpdfln(y(uncens_idx)', yPredMean(uncens_idx)', invYPredStd(uncens_idx)', 'inv'))');
ll = ll + sum(weights(cens_idx) .* (normcdfln( (-y(cens_idx)'+yPredMean(cens_idx)') .* invYPredStd(cens_idx)' ))');
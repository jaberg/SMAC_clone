function [nll, dnll, H] = negLogCensoredConditional(f, o, cens_idx, noncens_idx, invL_nonoise, invK_nonoise, sigma_n)
% negLogConditional returns a scalar proportinal to the *negative* log
% conditional likelihood p(f_m|o_m) as given in equation (12) of
% "Gaussian Process Models for Censored Sensor Readings" by
% Emre Ertin, 2007 IEEE 665-669,
% when the inverse of the kernel K is given, as well as its
% the inverse of K's lower triangular choelsky factor L.
% if cens(i)=1 then the ith data points is censored with censoring thresshold o(i)
%
% f_m are the true function values (called y instead in Ertin's paper)
% o_m are the observed values (lower bound if cens_m == 1, called t in Ertin's paper)
%
% By Frank Hutter, 11 Jan 2008.

ll=0;
% ll = ll + normpdfln(f, zeros(size(f,1),size(f,2)), invL, 'inv');
% Don't worry about the constants:
ll = ll - 0.5*f'*invK_nonoise*f;  % TODO: I think this can be faster by using invL_nonoise

ll = ll + sum(normpdfln( (o(noncens_idx)'-f(noncens_idx)')/sigma_n ) );

%=== The following is the other way around than in the above paper -
%=== I think it's a typo there.
normed_f_cens = (-o(cens_idx)+f(cens_idx))/sigma_n;
cdfln_cens = normcdfln(normed_f_cens');
ll = ll + sum(cdfln_cens);
nll = -ll;

if nargout > 1
    dll=zeros(length(f),1);
    %%   dll = -solve_chol(invL_nonoise',f); %=== Efficient version of dll = -inv(K)*f

    dll = -invK_nonoise*f;
    dll(noncens_idx) = dll(noncens_idx) -1/sigma_n^2 * (f(noncens_idx)-o(noncens_idx));
    %=== The regular formula for censoring is easier, but division by zero for cdf -> 0.
    pdfln_cens = normpdfln(normed_f_cens');
    dll(cens_idx) = dll(cens_idx) + exp(pdfln_cens - cdfln_cens - log(sigma_n))';

    dnll = -dll;
    assert(all(~isnan(dll)));
end

if nargout > 2
    H = getHessianOfNegLogCensoredConditional(f, o, invK_nonoise, cens_idx, noncens_idx, sigma_n);
end
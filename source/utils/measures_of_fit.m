function [rmse_w, ll_w, cc_w, cc_rank] = measures_of_fit(y, y_cross, y_cross_var, cens, weights)
%=== Compute RMSE, CC, and LL; the first two only on noncensored data.
%=== Also compute weighted versions.
if nargin < 5
    weights = ones(length(y),1);
    if nargin < 4
        cens = zeros(length(y),1);
        if nargin < 3
            y_cross_var = zeros(length(y),1);
        end
    end
end
assert(~any(isnan(y_cross_var)));
assert(~any(isinf(y_cross_var)));
assert(all(y_cross_var >= -1e-10));
y_cross_var =max(y_cross_var, 1e-10);
weights = weights/sum(weights);
noncens_idx = find(cens==0);

% rmse   = sqrt(  mean( (y_cross(noncens_idx)-y(noncens_idx)).^2) );
rmse_w = sqrt(w_mean( (y_cross(noncens_idx)-y(noncens_idx)).^2, weights(noncens_idx)) );

if all(y_cross_var==0)
%    ll = NaN;
    ll_w = NaN;
else
%    ll   = log_likelihood(y,y_cross,y_cross_var,cens);
    ll_w = log_likelihood(y,y_cross,y_cross_var,cens, weights);
end

% tmp = 0;
% for j=1:length(y_cross)
%     tmp = tmp + normpdfln(model.y(j), y_cross(j), [], y_cross_var(j));
% end
% assert(all(ll<tmp/length(y_cross)+1e-10) & all(ll>tmp/length(y_cross)-1e-10));

% cc = 0;
% if std(y_cross(noncens_idx)) > 1e-10
%     cc = corrcoef(y_cross(noncens_idx), y(noncens_idx));
%     cc=cc(1,2);
% end

cc_w = 0;
if ~isempty(noncens_idx)
    cc_w = w_corrcoef(y_cross(noncens_idx), y(noncens_idx), weights);
end

% % Spearman correlation coefficient (weighted, but using uniform weights)
% [tmp, sort_idx] = sort(y_cross);
% N = length(y_cross);
% ranks_y_cross = zeros(N,1);
% ranks_y = zeros(N,1);
% for i=1:N
%     ranks_y_cross(sort_idx(i),1) = i;
% end
% [tmp, sort_idx] = sort(y);
% for i=1:N
%     ranks_y(sort_idx(i),1) = i;
% end
% cc_w = w_corrcoef( ranks_y_cross, ranks_y, weights );

% cc_rank = 0;
%if std(y_cross(noncens_idx)) > 1e-10
%     [tmp, idx1] = mysort(y_cross(noncens_idx));
%     [tmp, idx2] = mysort(y(noncens_idx));
%     ranks1(idx1) = 1:length(noncens_idx);
%     ranks2(idx2) = 1:length(noncens_idx);
    
cc_rank = 0;
if ~isempty(noncens_idx)
    ranks1 = get_ranks(y_cross(noncens_idx));
    ranks2 = get_ranks(y(noncens_idx));
    
    if length(ranks1) == 1
        cc_rank = 1;
    else
        cc_rank = corrcoef(ranks1, ranks2);
        cc_rank = cc_rank(1,2);
    end
end

% function [sorted, sort_idx] = mysort(array)
% %=== Just like sort, but NOT preserving order -- instead random tie breaking
% perm = randperm(length(array));
% arrayperm = array(perm);
% [sorted, sort_idx_perm] = sort(arrayperm);
% sort_idx(:,1) = perm(sort_idx_perm);

function ranks = get_ranks(array)
%=== Compute ranks using stable sort on orig, and on inverted data.
N = length(array);
array_inv = zeros(N,1);
ranks1 = zeros(N,1);
ranks2 = zeros(N,1);

[tmp, idx1] = sort(array);
ranks1(idx1) = 1:N;

for i=1:N
    array_inv(i) = array(N+1-i);
end
[tmp, idx2] = sort(array_inv);
ranks_tmp(idx2) = 1:N;
for i=1:N
    ranks2(i) = ranks_tmp(N+1-i);
end

ranks = (ranks1 + ranks2)/2;


function weighted_mean = w_mean(x,w)
w = w/sum(w);
weighted_mean = sum(x.*w);

function weighted_var = w_var(x,w)
w = w/sum(w);
weighted_var = sum(w.* ((x-w_mean(x,w)).^2));

function weighted_cov = w_cov(x,y,w)
w = w/sum(w);
weighted_cov = sum(w.* ((x-w_mean(x,w)) .* (y-w_mean(y,w))));

function weighted_corrcoeff = w_corrcoef(x,y,w)
w = w/sum(w);
weighted_corrcoeff = w_cov(x,y,w) / (sqrt(w_var(x,w)) * sqrt(w_var(y,w)));
if isnan(weighted_corrcoeff)
    weighted_corrcoeff = 0;
end
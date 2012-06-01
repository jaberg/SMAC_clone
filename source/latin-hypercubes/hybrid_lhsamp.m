function S = hybrid_lhsamp(dim, cat, sizes, N, lower, upper)
%HYBRID_LHSAMP  Latin hypercube distributed random numbers for continuous vars,
%               discrete samples for categorical vars 
%
% Call:    S = hybrid_lhsamp(dim, cat, sizes, N, lower, upper)
%
% dim: number of dimensions
% cat: indicator vector of sizes 1,dim. cat(i)=1 <=> ith var is categorical)
% sizes: 0 for continuous vars. sizes(i)=j <=> var i can take j possible values
% N: number of sample points to generate, if unspecified N = 1 
% lower: 1,dim vector. Only relevant for continuous vars, lower bound
% upper: 1,dim vector. Only relevant for continuous vars, upper bound
%
% S : the N generated dim-dimensional sample points

% hbn@imm.dtu.dk , modified for categorical vars by Frank Hutter
% Last update November 28, 2007

if nargin < 1, dim = 1; end
if nargin < 2, cat = zeros(1,dim); end
if nargin < 3, sizes = 2*ones(1,dim); end
if nargin < 4, N = 1; end
if nargin < 5, lower = zeros(1,dim); end
if nargin < 5, upper = ones(1,dim); end

S = zeros(N,dim);
for i=1:dim
    if cat(i)
        tmp = [];
        while length(tmp) < N
            tmp = [tmp, randperm(sizes(i))'];
        end
        S(:, i) = tmp(1:N)';
    else
        S(:, i) = lower(i) + ((rand(1, N) + (randperm(N) - 1))' / N) * (upper(i)-lower(i));
    end
end

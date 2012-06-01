function S = random_design(dim, cat, size, N, lower, upper)
%RANDOM_DESIGN  Random numbers for continuous vars,
%               discrete samples for categorical vars 
%
% Call:    S = random_design(dim, cat, size, N, lower, upper)
%
% dim: number of dimensions
% cat: indicator vector of size 1,dim. cat(i)=1 <=> ith var is categorical)
% size: 0 for continuous vars. size(i)=j <=> var i can take j possible values
% N: number of sample points to generate, if unspecified N = 1 
% lower: 1,dim vector. Only relevant for continuous vars, lower bound
% upper: 1,dim vector. Only relevant for continuous vars, upper bound
%
% S : the N generated dim-dimensional sample points

if nargin < 1, dim = 1; end
if nargin < 2, cat = zeros(1,dim); end
if nargin < 3, size = 2*ones(1,dim); end
if nargin < 4, N = 1; end
if nargin < 5, lower = zeros(1,dim); end
if nargin < 5, upper = ones(1,dim); end

S = zeros(N,dim);
for i=1:dim
    if cat(i)
        r = ceil(size.*rand(N,1));
        S(:, i) = r;
    else
        S(:, i) = lower(i) + (rand(N, 1) * (upper(i)-lower(i));
    end
end
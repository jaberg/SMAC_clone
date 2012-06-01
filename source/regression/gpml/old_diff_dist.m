% diff_dist - a function to compute a matrix of all pairwise weighted 
% Hamming distances between two sets of vectors, stored in the columns 
% of the two matrices, a (of size D by n) and b (of size D by m). 
% If b is empty, it is taken to be identical to a.
%
% TODO: The program code is written in the C language for efficiency and is
% contained in the file sq_dist.c, and should be compiled using matlabs mex
% facility. However, this file also contains a (less efficient) matlab
% implementation, supplied only as a help to people unfamiliar with mex. If
% the C code has been properly compiled and is avaiable, it automatically
% takes precendence over the matlab code in this file.
%
% Usage: C = diff_dist(a, b, inv_w)
% where the b matrix may be empty.
%
% where a is of size D by n, b is of size D by m (or empty), 
% length_scale is of size D by 1, and C is of size n by m.

function C = diff_dist(a, b, invw);

if nargin ~= 3 | nargout > 1
  error('Wrong number of arguments.');
end

if isempty(b)                   % input arguments are taken to be
  b = a;                                   % identical if b is missing or empty
end 

[D, n] = size(a); 
[d, m] = size(b);
if d ~= D
  error('Error: column lengths must agree.');
end

C = zeros(n,m);
for d = 1:D
%    C = C + min(abs(repmat(b(d,:), n, 1) - repmat(a(d,:)', 1, m)),1);
    C = C + 1 - (repmat(b(d,:), n, 1) == repmat(a(d,:)', 1, m));
end
% Maybe something like C = repmat(sum(a.*a)',1,m)+repmat(sum(b.*b),n,1)-2*a'*b could be used to 
% replace the 3 lines above; it would be faster, but numerically less
% stable.
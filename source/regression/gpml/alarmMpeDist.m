% w_ham_dist - a function to compute a matrix of all pairwise weighted 
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
% Usage: C = w_ham_dist(a, b, inv_w)
% where the b matrix may be empty.
%
% where a is of size D by n, b is of size D by m (or empty), 
% length_scale is of size D by 1, and C is of size n by m.

function C = alarmMpeDist(a, b);

global alarmBnet
if isempty(alarmBnet)
    alarmBnet = mk_alarm_bnet;
end

if nargin ~= 2 | nargout > 1
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

aLik = zeros(n,1);
bLik = zeros(m,1);

for i=1:n
    aLik(i) = log_lik_complete(alarmBnet, a(:,i));
end
for i=1:m
    bLik(i) = log_lik_complete(alarmBnet, b(:,i));
end

C = zeros(n,m);
for i=1:n
    for j=1:m
%        C(i,j) = exp(-abs(xLik(i)-zLik(j)));
        C(i,j) = abs(aLik(i)-bLik(j));
    end
end
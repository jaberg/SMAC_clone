function result = log_diff_exp(logA, logB)
% Computes log(A-B) only using log(A) and log(B). Assumes A>0, B<0, |A|>|B|.
% Inputs: logA = log(A), logB = log(B)
% Output: log(A-B)
result = logA + log(1 - exp(logB-logA));
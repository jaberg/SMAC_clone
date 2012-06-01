function result = log_sum_exp(logA, logB)
% Computes log(A+B) only using log(A) and log(B). This assumes A>0, B>0.
% Inputs: logA = log(A), logB = log(B)
% Output: log(A+B)
% After writing this, I found that lightspeed has it, too, but not
% log_diff_exp.
result = max(logA,logB) + log(1 + exp(-abs(logA-logB)));
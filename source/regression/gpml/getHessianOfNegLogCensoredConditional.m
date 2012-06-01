function H = getHessianOfNegLogCensoredConditional(f_bar, y, invK_nonoise, cens_idx, noncens_idx, sigma_n)
%=== Compute the Hessian H of the log likelihood p(f_{1:n}|y_{1:n}, cens_{1:n}).

diag_add = zeros(length(y),1);
diag_add(noncens_idx) = -1/sigma_n^2;
if ~isempty(cens_idx)
    normed_diff = (f_bar(cens_idx)-y(cens_idx))/sigma_n;

    %=== To avoid numerical problems: log(a+b) trick
    pos_idx = find(normed_diff>0);
    same_idx = find(normed_diff==0);
    neg_idx = find(normed_diff<0);
    log_A_plus_B = zeros(length(cens_idx),1);
    logB = 2*normpdfln(normed_diff')';

    %=== pos_idx
    if ~isempty(pos_idx)
        logA = log(f_bar(cens_idx(pos_idx))-y(cens_idx(pos_idx))) + log(1/sigma_n) + normcdfln(normed_diff(pos_idx)')' + normpdfln(normed_diff(pos_idx)')';
        log_A_plus_B(pos_idx) = log_sum_exp(logA, logB(pos_idx));
    end

    %=== neg_idx
    if ~isempty(neg_idx)
        logMinusA = log(-f_bar(cens_idx(neg_idx))+y(cens_idx(neg_idx))) + log(1/sigma_n) + normcdfln(normed_diff(neg_idx)')' + normpdfln(normed_diff(neg_idx)')';
        %=== Saveguard against there being no detectable difference even in the logs of A and B -> return infinity.
        if any(logMinusA==logB(neg_idx))
            for i=1:length(neg_idx)
                if logMinusA(i) == logB(neg_idx(i))
                    log_A_plus_B(neg_idx(i)) = -inf;
                else
                    log_A_plus_B(neg_idx(i)) = log_diff_exp(logB(neg_idx(i)),logMinusA(i));
                end
            end
        else
            log_A_plus_B(neg_idx) = log_diff_exp(logB(neg_idx),logMinusA);
        end
    end
    
    %=== same_idx 
    if ~isempty(same_idx)
        log_A_plus_B(same_idx) = logB(same_idx);
    end

    log_add = log_A_plus_B - 2*normcdfln(normed_diff')';
    diag_add(cens_idx) = -1/sigma_n^2 * exp(log_add);
end
H = -(-invK_nonoise + diag(diag_add));
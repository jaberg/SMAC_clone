fun = @(x) sum((x-0.5).^2);
D = 3;
x_0 = zeros(1,D);
lb = -ones(1,D);
ub = ones(1,D);
max_fun_evals = 100*D;
options.seed = 1;
[min_x, min_val] = smbo_wrap_simple(fun, x_0, lb, ub, max_fun_evals, options);
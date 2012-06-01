function [w, wObj, hist] = direct_wrapper(f, x, options, gradf, varargin)
    opts.maxevals = 1000 * round(length(x)^1.3); %^2;   % MC - reduced iterations cus it takes too long
    opts.maxits = 100 * round(length(x)^1.3); %^2;
    opts.showits = 1;
    % Set bounds, quite arbitrary to -10 and 10.
    bounds(1:length(x),1) = -10;
    bounds(1:length(x),2) = 10;
    
    Problem.f = f;
    [wObj, w, hist] = Direct_rowvector(Problem, bounds, opts, varargin{:});
    w=w';
end
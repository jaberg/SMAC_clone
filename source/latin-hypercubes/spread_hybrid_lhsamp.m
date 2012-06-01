function design = spread_hybrid_lhsamp(seed, dim, N, cat, cont, numvalues, params_bounds, lhd_method, use_seed)
%HYBRID_LHSAMP  Latin hypercube distributed random numbers for continuous vars,
%               equivalent for categorical vars.
%
% seed: random seed to use
% dim: number of dimensions
% N: number of sample points to generate, if unspecified N = 1 
% numvalues: 1 by d array containing the number of possible 
%            values for each of the categorical parameters.
% params_bounds: 2 by D vector, containing lower and upper bound for 
%                each of the continuous parameters. 
%
% OUTPUT:
% design: the N generated dim-dimensional sample points

assert(length(cat) + length(cont) == dim);

if nargin < 1, seed = 1; end
if nargin < 2, dim = 1; end
if nargin < 3, cat = zeros(1,dim); end
if nargin < 4, sizes = 2*ones(1,dim); end
if nargin < 5, N = 1; end
if nargin < 6, lower = zeros(1,dim); end
if nargin < 7, upper = ones(1,dim); end
if nargin < 8, values = {}; end

%seed = ceil(10000000*rand);

%=== Call code for improved distributed hypercube sampling algorithm.
%if dim==2 & N==21 % design used by Welch et al for 2D.
%    X = [16;11;7;2;19;14;9;3;20;15;1;10;6;18;13;3;21;8;17;12;4];
%    X = [X, (1:21)'];

if use_seed
    orig_seed = rand('twister'); 
    rand('twister',seed);
end
switch lhd_method
    case 'ihs'
        X = ihs(dim, N, 5, seed)';
        %=== Bring it into a nice form for my purposes.
        %=== For categorical variables with K values, map 1:(N/K) to 1,
        %=== (N/K)+1:(2*N/K) to 2, (2*N/K)+1:(3*N/K) to 3, ..., ((K-1)*N/K)+1:(K*N/K) to K

        design = zeros(N,dim);
        for i=1:dim
            if ismember(i, cat)
                design(:, i) = ceil(X(:,i)/N*numvalues(i));
            else
                design(:, i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)).*(X(:,i) - 1)/(N-1);
            end
        end
        if use_seed
            rand('twister',orig_seed);
        end
        return
        
    case 'matlab'
        X = lhsdesign(N, dim, 'smooth','off');
        
        design = zeros(N,dim);
        for i=1:dim
            if ismember(i, cat)
                design(:, i) = ceil(X(:,i)*numvalues(i));
            else
                design(:, i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)).*(X(:,i));
            end
        end
        if use_seed
            rand('twister',orig_seed);
        end
        return
    
    case 'sko'
        X= [    0.5625    0.1875    0.3125    0.7125; ...
                0.6375    0.9375    0.6875    0.1375; ...
                0.9125    0.5625    0.6625    0.5375; ...
                0.6875    0.5375    0.5375    0.4125; ...
                0.4875    0.2875    0.5875    0.0375; ...
                0.0625    0.4375    0.5125    0.4625; ...
                0.4625    0.8375    0.8375    0.8375; ...
                0.1875    0.0625    0.0125    0.6875; ...
                0.6125    0.4625    0.6125    0.8875; ...
                0.3625    0.2625    0.2375    0.3875; ...
                0.1125    0.1375    0.8625    0.5875; ...
                0.5875    0.7625    0.4125    0.1125; ...
                0.3125    0.0375    0.1875    0.9125; ...
                0.8875    0.4875    0.7625    0.7875; ...
                0.4375    0.0125    0.4875    0.2875; ...
                0.8125    0.3625    0.3375    0.0875; ...
                0.2375    0.6625    0.7125    0.6125; ...
                0.2625    0.1125    0.5625    0.0625; ...
                0.0375    0.2125    0.4625    0.7375; ...
                0.0125    0.3125    0.2875    0.2125; ...
                0.7875    0.4125    0.8125    0.2625; ...
                0.8625    0.6125    0.1375    0.9625; ...
                0.0875    0.5125    0.1625    0.4375; ...
                0.9625    0.9875    0.6375    0.9875; ...
                0.9875    0.6875    0.0375    0.3375; ...
                0.9375    0.9125    0.9875    0.9375; ...
                0.2125    0.8125    0.8875    0.8625; ...
                0.1375    0.3375    0.0875    0.7625; ...
                0.3875    0.7375    0.2125    0.5125; ...
                0.8375    0.7875    0.2625    0.2375; ...
                0.3375    0.1625    0.9625    0.3125; ...
                0.7375    0.2375    0.3625    0.3625; ...
                0.1625    0.0875    0.3875    0.5625; ...
                0.2875    0.8625    0.4375    0.6375; ...
                0.7125    0.9625    0.9375    0.8125; ...
                0.4125    0.6375    0.7875    0.0125; ...
                0.5125    0.3875    0.9125    0.1625; ...
                0.5375    0.5875    0.1125    0.1875; ...
                0.7625    0.8875    0.7375    0.4875; ...
                0.6625    0.7125    0.0625    0.6625];
            
        X = [X,repmat(1,[40,1])];
        
        design = zeros(N,dim);
        for i=1:dim
            if ismember(i, cat)
                design(:, i) = ceil(X(:,i)*numvalues(i));
            else
                design(:, i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)).*(X(:,i));
            end
        end
        if use_seed
            rand('twister',orig_seed);
        end
        return

    case 'random_lhd'
        X = hybrid_lhsamp(dim, ones(1,dim), N*ones(1,dim), N);
        design = zeros(N,dim);
        for i=1:dim
            if ismember(i, cat)
                design(:, i) = ceil(X(:,i)/N*numvalues(i));
            else
                design(:, i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)).*(X(:,i) - 1)/(N-1);
            end
        end
        if use_seed
            rand('twister',orig_seed);
        end
        return

    case 'inc_lhd'
        design = -ones(N,dim);
        for i=1:dim
            idx = 0;
            if ismember(i,cat)
                nval = numvalues(i);
                while idx < N - nval
                    design(idx+1:idx+nval,i) = randperm(nval)';
                    idx = idx + nval;
                end
                diff = N-idx;
                if diff > 0
                    R = randperm(nval)';
                    design(idx+1:N,i) = R(1:diff);
                end
            else
                design(:,i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)) * rand(N,1);
            end
        end
        return
        
        
    case 'random'
        design = -ones(N,dim);
        for i=1:dim
            if ismember(i,cat)
                design(:,i) = ceil(rand(N,1) * numvalues(i));
            else
                design(:,i) = params_bounds(i,1) + (params_bounds(i,2)-params_bounds(i,1)) * rand(N,1);
            end
        end
        if use_seed
            rand('twister',orig_seed);
        end
        return
        
    otherwise
        error 'Unknown lhd_method'
end

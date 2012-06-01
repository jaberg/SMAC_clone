function [x, bestObj, changed, totalCount] = general_basic_local_search_mixed_disc_cont(funcHandle, xStart, cat, domains, cond_params, parent_param, ok_parent_values, varargin)
%=== Hill climbing to maximize the discrete-input function in funcHandle,
%=== where input i can take values from the cell array entry domains{i}.
dim = size(xStart, 2);
cont = setdiff(1:dim, cat);
eps = 1e-5;
changed = 0;
x = xStart;
totalCount = 0;
if isempty(varargin)
    startObj = funcHandle(x);
else
    startObj = funcHandle(x, varargin{:});
end
bestObj = startObj;
while 1
    activeCat = [];
    activeCont = [];
    %=== Eliminate non-active parameters from cat and cont.
    for var = cat
        if is_active(var, x, cond_params, parent_param, ok_parent_values)
            activeCat = [activeCat, var];
        end
    end
    for var = cont
        if is_active(var, x, cond_params, parent_param, ok_parent_values)
            activeCont = [activeCont, var];
        end
    end
    
    if isempty(activeCat) && isempty(activeCont)
        error('No active parameters. This cannot be!');
        return;
    end
    
    %=== Vectorized version of neighbourhood evaluation.
    %=== 1) Create list of neighbours
    numContNeighb = 4;
    numNeighbours = 0;
    for var=activeCat
        numNeighbours = numNeighbours + length(domains{var})-1;
    end
    for var=activeCont
        numNeighbours = numNeighbours + numContNeighb;
    end
    
    neighbours = repmat(x, [numNeighbours,1]);
    var_at_count = -ones(numNeighbours, 1);
    val_at_count = -ones(numNeighbours, 1);
    
    count = 1;
    for var=activeCat
        vals = domains{var};
        for val=vals
            if val==x(var), continue, end
            neighbours(count,var) = val;
            var_at_count(count) = var;
            val_at_count(count) = val;
            count = count + 1;
            totalCount = totalCount + 1;
        end
    end
    for var=activeCont
        for i=1:numContNeighb
            while 1 % rejection sampling of N( x(var), 0.2 ) in the interval [0,1] (acceptance probability >= 0.5, so not too expensive)
                val = x(var) + 0.2*randn;
                if val >= 0 && val <= 1
                    break;
                end
            end
            neighbours(count,var) = val;
            var_at_count(count) = var;
            val_at_count(count) = val;
            count = count + 1;
            totalCount = totalCount + 1;
        end
    end
    
    %=== 2) Evaluate all neighbours at once.
    if isempty(varargin)
        objs = funcHandle(neighbours);
    else
        objs = funcHandle(neighbours, varargin{:});
    end

    %=== 3) Pick one of the best neighbours.
    [minObj, minInd] = min(objs);
    if minObj >= bestObj-eps, break, end;
    
    minInds = find(objs <= minObj + eps);
    chosen_idx = ceil(rand*length(minInds));
    minInd = minInds(chosen_idx);
    
    x(var_at_count(minInd)) = val_at_count(minInd);
    bestObj=minObj;
    %fprintf(['LS: totalCount=', num2str(totalCount), ', bestObj=', num2str(bestObj), '\n'])
%     bout(sprintf(['LS: totalCount=', num2str(totalCount), ', bestObj=', num2str(bestObj), '\n']));
    changed = 1;
end
%expected_imp = exp(-minObj);


function isactive = is_active(var, x, cond_params, parent_param, ok_parent_values)
cond_idxs = find(cond_params == var);
isactive = true;
for i=1:length(cond_idxs)
    parent = parent_param(cond_idxs(i));
    ok_values = ok_parent_values{cond_idxs(i)};
    if ~ismember(x(parent), ok_values)
        isactive = false;
    end
end
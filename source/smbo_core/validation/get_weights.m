function weights = get_weights(vectorToBeSorted)
N = length(vectorToBeSorted);
[tmp, sort_idx] = sort(vectorToBeSorted);
for i=1:N
    ranks(sort_idx(i),1) = i;
end

% weights = (N-ranks)+1;
weights = 0.95.^ranks;

weights = weights / sum(weights);

function random_configs = selectRandomConfigs(func, numConfigs)

random_configs = zeros(numConfigs, func.dim);
for j=func.cat
    random_configs(:,j) = ceil( rand(numConfigs,1) * func.num_values(j) );
end
for j=func.cont
    random_configs(:,j) = rand(numConfigs,1) * (func.param_bounds(j,2)-func.param_bounds(j,1)) + func.param_bounds(j,1);
end
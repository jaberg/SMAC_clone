function func = makeFunc( params_filename)
[func.cat, func.cont, func.param_names, func.all_values, func.param_bounds, func.param_trafo, func.is_integer_param, func.default_values, func.cond_params_idxs, func.parent_param_idxs, func.ok_parent_value_idxs] = read_params(params_filename);
func = processFunc(func);
end


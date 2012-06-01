function options = set_options(in_options)

options = get_default_smbo_opts;

fields = fieldnames(in_options);
for i=fields'
    options.(char(i)) = in_options.(char(i));
end

options.totalNumRunLimit = max(options.totalNumRunLimit, 1); %at least one run for the default!
options.ppSize = options.trainSubSize;

if strcmp(options.overallobj , 'mean10')
    options.cutoff_penalty_factor = 10;
elseif strcmp(options.overallobj , 'mean')
    options.cutoff_penalty_factor = 1;
elseif strcmp(options.overallobj, 'median')
    options.cutoff_penalty_factor = 1;
else
    error 'need to implement objectives other than mean and mean10'
end
% Now done in init.
% options.tuning_params = [options.split_ratio_init, options.Splitmin_init/options.splitMinMax, options.Splitmincens_init/options.splitMinMax];
% % Pack parameters.
% options.tuning_params = options.paramsLowerBound + options.tuning_params .* (options.paramsUpperBound - options.paramsLowerBound);
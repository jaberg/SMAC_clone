function [numPCA, Splitmin, split_ratio] = unpack_params(al_opts)
numPCA = round(al_opts.maxPCA * al_opts.tuning_params(1));
Splitmin = ceil(al_opts.splitMinMax * al_opts.tuning_params(2));
split_ratio = al_opts.tuning_params(3);
function model = initModel(Theta_inst_idxs, ThetaUniqSoFar, all_instance_features, y, cens, thetaCat, thetaCatDomains, xCat, xCatDomains, cond_params_idxs, parent_param_idxs, ok_parent_value_idxs, options, names)
%=== Initialize and put data into model, but don't do any work yet.
if nargin < 14
    names = {};
end

%=== Assert the inputs are fine.
assert(all(isfinite(y)));
assert(all(isfinite(cens)));
Theta = ThetaUniqSoFar(Theta_inst_idxs(:,1),:);
insts = all_instance_features(Theta_inst_idxs(:,2),:);
assert(all(all(isfinite(Theta))));
assert(all(all(isfinite(insts))));

nvars = size(ThetaUniqSoFar, 2) + size(all_instance_features, 2);

cat = [thetaCat, length(thetaCat) + xCat];
catDomains = [thetaCatDomains, xCatDomains];

cat_domain_sizes = zeros(nvars, 1);
for i=cat'
    cat_domain_sizes(i) = length(catDomains{i});
    if cat_domain_sizes(i) == 0
        error('cannot have empty domain for cat var.');
    end
end

%=== Remember inputs.
model.X = [Theta, insts];
model.Theta_inst_idxs = Theta_inst_idxs;
model.ThetaUniqSoFar = ThetaUniqSoFar;
model.all_instance_features = all_instance_features;
model.y = y;
model.cens = cens;
model.cat = cat;
model.cont = setdiff(1:nvars, model.cat);
model.catDomains = catDomains;
model.cat_domain_sizes = cat_domain_sizes;
model.cond = cond_params_idxs;
model.condParent = parent_param_idxs;
model.condParentVals = ok_parent_value_idxs;
model.type = options.modelType;
model.options = options;
model.names = names;

%=== Model-specific initialization.

switch options.modelType

    case {'rf', 'javarf', 'fastrf'}       
        model.options.tuning_params = [model.options.split_ratio_init; model.options.Splitmin_init/model.options.splitMinMax; model.options.Splitmincens_init/model.options.splitMinMax];
        model.options.tuning_params = model.options.paramsLowerBound + model.options.tuning_params .* (model.options.paramsUpperBound - model.options.paramsLowerBound);
        model.params = model.options.tuning_params;
        
    case 'GP-matern3'
        covfunc = {'covMatern3iso'};
        loghyper = zeros(2, 1);
    case 'GP-matern5'
        covfunc = {'covMatern5iso'};
        loghyper = zeros(2, 1);
    case 'GP-matern3noise'
        covfunc = {'covSum', {'covMatern3iso','covNoise'}};
        loghyper = zeros(3, 1);
    case 'GP-matern5noise'
        covfunc = {'covSum', {'covMatern5iso','covNoise'}};
        loghyper = zeros(3, 1);

    case 'GP-SEiso'
        covfunc = 'covSEiso';
        loghyper = zeros(2, 1);
    case 'GP-SEard'
        covfunc = {'covSEard'};
        loghyper = zeros(1 + size(model.X,2), 1);
    case 'GP-SEardnoise'
        covfunc = {'covSum', {'covSEard','covNoise'}};
        loghyper = zeros(2 + size(model.X,2), 1);
    case 'GP-SEisonoise'
        covfunc = {'covSum', {'covSEiso','covNoise'}};
        loghyper = zeros(3, 1);

    case 'GP-covRQardnoise'
        covfunc = {'covSum', {'covRQard','covNoise'}};
        loghyper = zeros(3 + size(model.X,2), 1);

    case 'GP-DIFFiso'
        covfunc = 'covDIFFiso';
        loghyper = zeros(2, 1);
    case 'GP-DIFFard'
        covfunc = 'covDIFFard';
        loghyper = zeros(1 + size(model.X,2), 1);

    case 'GP-hybridiso'
        covfunc = 'covHybridSE_DIFFiso';
        loghyper = zeros(2, 1);
    case 'GP-hybridard'
        covfunc = 'covHybridSE_DIFFard';
        loghyper = zeros(1 + size(model.X,2), 1);
    case 'GP-hybridisonoise'
        covfunc = {'covSum', {'covHybridSE_DIFFiso','covNoise'}};
        loghyper = zeros(3, 1);
    case {'GP-hybridardnoise', 'GPML'}
        covfunc = {'covSum', {'covHybridSE_DIFFard','covNoise'}};
        loghyper = zeros(2 + size(model.X,2), 1);
    case 'GP-hybridisoNoLen'
        covfunc = 'covHybridSE_DIFFiso_NoLen';
        loghyper = zeros(1, 1);
    case 'GP-hybridisoNoLennoise'
        covfunc = {'covSum', {'covHybridSE_DIFFiso_NoLen','covNoise'}};
        loghyper = zeros(2, 1);
    case 'GP-hybridisoOnlyLen'
        covfunc = 'covHybridSE_DIFFiso_OnlyLen';
        loghyper = zeros(1, 1);
    case 'GP-hybridisoOnlyLennoise'
        covfunc = {'covSum', {'covHybridSE_DIFFiso_OnlyLen','covNoise'}};
        loghyper = zeros(2, 1);

    case 'GP-covHybridSE_DIFFiso_algo'
        covfunc = {'covSum', {'covHybridSE_DIFFiso_algo','covNoise'}};
        loghyper = zeros(4, 1);

    case 'GP-AlarmMPE'
        covfunc = 'covAlarmMPE';
        loghyper = [log(1e-2)];
        
    otherwise
        error ('No such model type defined yet!');
end

%=== If we work with a subset of the data for optimization, set that index.
if isfield(options, 'trainSubSize') && options.trainSubSize > 0
    index = randperm(length(y));
    model.opt_index = index(1:min(length(y), options.trainSubSize));
end
%=== If we employ the projected process approximation, set the index for that.
if isfield(options, 'ppSize') && options.ppSize > 0
    index = randperm(length(y));
    model.pp_index = index(1:min(length(y), options.ppSize));
end

if strfind(options.modelType, 'GP')
    model.options.opt=1;
    model.params = loghyper;

    if ischar(covfunc), covfunc = cellstr(covfunc); end % convert to cell if needed
    [n, D] = size(model.X);
    if eval(feval(covfunc{:})) ~= size(model.params, 1)
        error('Error: Number of parameters does not agree with covariance function')
    end
    model.covfunc = covfunc;

    if length(covfunc) == 2 & strcmp(covfunc(1), 'covSum') & strcmp(covfunc{2}(end), 'covNoise')
        model.noisy = 1;
        model.params(1:end-2) = 1; % start optimization with quite high length scale!
        model.params(end-1) = 0; % signal variance, average
        model.params(end) = -1; % start optimization with quite low noise!
    end
    model.meanToAdd = mean(model.y);
    model.y = model.y - model.meanToAdd;
else
    model.options.ppSize = 0;
end

model.prepared = 0;

assert(all(isfinite(model.y)));

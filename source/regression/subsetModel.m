function model = subsetModel(origModel, index)
%=== Construct a model using only subset index of the data in the original model.

% if origModel.al_opts.ppSize > 0
%     if length(intersect(index, origModel.pp_index)) < length(origModel.pp_index)
%         error 'Tossing entries from the active set -- not implemented yet.'
%     end
% end

model = origModel;
%model.origY = model.origY(index);
%model.origX = model.origX(index, :);
model.cens = model.cens(index);
model.X = model.X(index, :);
model.y = model.y(index);

if isfield(origModel.options, 'all_theta_idxs')
    model.options.all_theta_idxs = origModel.options.all_theta_idxs(index);
end

model.prepared = 0;
    
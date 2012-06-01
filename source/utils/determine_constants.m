function constants = determine_constants(xTrain, trafo)

xTrainDefault=xTrain*0+1;
xTrainDefault(find(xTrain==-512 | xTrain==-1024))=2; % -512 and -1024 are special values signaling missing values or broken features.

nonconstant = determine_transformation(xTrain, xTrainDefault, trafo);
constants = setdiff(1:size(xTrain,2), nonconstant);

%bout(fprintf('Discarding %i constant features of %i in total.\n', length(constants), size(xTrain,2)));
bout(sprintf('Discarding %i constant inputs of %i in total.\n', length(constants), size(xTrain,2)));
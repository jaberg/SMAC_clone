function [nll] = summedCrossValLL(params, model)
nll = 0;
nTotal = 0;
for i=1:length(model.module)
    nModule = length(model.module{i}.y);
    nTotal = nTotal + nModule;
    nll = nll + nModule * crossValLL(params, model.module{i});
end
nll = nll / nTotal;
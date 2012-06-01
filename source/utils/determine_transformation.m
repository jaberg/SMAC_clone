function [nonconstant, scale, bias] = determine_transformation(xTrain, xTrainDefault, trafo)

if nargin <= 1
    trafo = 1;
end

[N, dim] = size(xTrain);

% normalize data w.r.t. training data.
nonconstant = [];

%trafo = 1; % mean 0, std=1
%trafo = 2; % between 0 and 1.
%trafo = 3; % no normalization.

[N, dim] = size(xTrain);
scale = [];
bias = [];
for i=1:dim
    
    if trafo == 1
        foo=xTrain(:,i);
        foo=foo(find(xTrainDefault(:,i)<2));
        bias(i) = mean(foo);
    elseif trafo == 2
        foo=xTrain(:,i);
        foo=foo(find(xTrainDefault(:,i)<2));
        bias(i) = min(foo);
    else
        bias(i) = 0;
    end

    %=== Subtract bias.
    xTrain(:,i) = xTrain(:,i) - bias(i);
    
    if trafo == 1
        foo=xTrain(:,i);
        foo=foo(find(xTrainDefault(:,i)<2));
        scale(i) = std(foo);
    elseif trafo == 2
        foo=xTrain(:,i);
        foo=foo(find(xTrainDefault(:,i)<2));
        scale(i) = max(foo);
    else
        if(max(xTrain(find(xTrainDefault(:,i)<2),i)) < min(xTrain(:,i)) + 1e-10)
            scale(i) = 0;
        else
            scale(i) = 1;
        end
    end
end

%=== Filter out constant columns.
num_nonconstant = 0;
for i=1:dim
    if scale(i) >= 1e-6
        num_nonconstant = num_nonconstant+1;
        nonconstant(num_nonconstant) = i;
    end
end
if num_nonconstant > 0
    bias = bias(nonconstant);
    scale = scale(nonconstant);
end
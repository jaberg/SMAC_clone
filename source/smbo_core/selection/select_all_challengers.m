function [challengers, eiTime, valStats] = select_all_challengers(func, model, means, vars, options, incumbent_theta_idx, valdata, valStats, rundata, learnTime)

[ei_challengers, eiTime, valStats] = select_challengers_with_EI(func, model, means, vars, incumbent_theta_idx, options, valdata, valStats, rundata, learnTime);
if options.onlyOneChallenger
    %=== Pick the first challenger we haven't tried yet.
    global ThetaUniqSoFar;
    for i=1:size(ThetaUniqSoFar,1)
        challengers = ei_challengers(i,:);
        if ~ismember(challengers, ThetaUniqSoFar, 'rows')
            break;
        end
    end
    return;
end

random_challengers = selectRandomConfigs(func, size(ei_challengers,1));

%=== Then, interleave EI and random challengers. Fraction of random ones could be a parameter, but is currently not.
challengers = zeros(size(ei_challengers,1)+size(random_challengers,1), size(ei_challengers,2));
count = 0;
for i=1:size(ei_challengers,1)
    challengers(count+1:count+2,:) = [ei_challengers(i,:); random_challengers(i,:)];
    count = count+2;
end
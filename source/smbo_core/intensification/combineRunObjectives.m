function quality = combineRunObjectives(overallobj, singlePerformances, cutoff)
%=== Objective function -- apply for each row, and return column vector of combined results.

[N,M] = size(singlePerformances);
% quality = -ones(N,1);
% for i=1:N
%     switch overallobj
%         case 'mean10'
%             bad = find(singlePerformances(i,:) >= cutoff - 0.0001);
%             singlePerformances(i,bad) = singlePerformances(i,bad) * 10;
%             quality(i) = mean(singlePerformances(i,:));
%         case 'mean'
%             quality(i) = mean(singlePerformances(i,:));
%         case 'median'
%             quality(i) = median(singlePerformances(i,:));
%         otherwise
%             error strcat(['Unknown overall objective'], overallobj);
%     end
% end

switch overallobj
    case 'mean10'
        singlePerformances(find(singlePerformances > cutoff - 1e-6)) = cutoff*10;
        quality = mean(singlePerformances, 2);
    case 'mean'
        quality = mean(singlePerformances, 2);
    case 'median'
        quality = median(singlePerformances, 2);
    otherwise
        error strcat(['Unknown overall objective'], overallobj);
end

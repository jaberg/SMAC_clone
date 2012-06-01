function transformed_config = config_transform(orig_config, func)

transformed_config = orig_config;
for i=1:func.dim
    if ismember(i, func.cont)
        %=== Linearize.
        transformed_config(:,i) = param_transform(transformed_config(:,i), func.param_trafo(i));
        
        %=== Normalize to [0,1]
        transformed_config(:,i) = (transformed_config(:,i) - func.transformed_param_lower_bound(i)) / (func.transformed_param_upper_bound(i)-func.transformed_param_lower_bound(i));
% === no transform for cat. variables; because they don't have to be numerical
%     else
%         %=== Search for matching string in func.all_values, use the index of that.
%         for k=1:size(transformed_config,1)
%             idx = 0;
%             for j=1:length(func.all_values{i})
%                 if strcmp(func.all_values{i}{j}, num2str(transformed_config(k,i)))
%                     idx = j;
%                     break;
%                 end
%             end
%             assert(idx>0); % otherwise value doesn't exist
%             transformed_config(k,i) = idx;
%         end
     end
end
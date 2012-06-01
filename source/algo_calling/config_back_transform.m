function orig_config = config_back_transform(transformed_config, func)
assert(size(transformed_config,2) == func.dim);

orig_config = transformed_config;
for i=1:func.dim
    if ismember(i, func.cont)
        %=== Undo normalization to [0,1]
        orig_config(:,i) = orig_config(:,i) * (func.transformed_param_upper_bound(i)-func.transformed_param_lower_bound(i)) + func.transformed_param_lower_bound(i);

        %=== Undo linearization.
        orig_config(:,i) = param_back_transform(orig_config(:,i), func.param_trafo(i));

        if func.is_integer_param(i)
            %=== Round to integer.
            orig_config(:,i) = round(orig_config(:,i));
        end

%         %=== Round continuous parameters to 4 digits -- otherwise DB problems !
%         if ~func.matlab_fun % don't do this if it's just a Matlab function without DB storage
%             orig_config(:,i) = floor(orig_config(:,i).*10000 + 0.5)/10000;
%         end
%     else
% % === no transform for cat. variables; because they don't have to be numerical
%         %=== Use appropriate values from func.all_values.
%         for k=1:size(orig_config,1)
%             orig_config(k,i) = func.all_values{i}{orig_config(k,i)};
%         end
    end
end
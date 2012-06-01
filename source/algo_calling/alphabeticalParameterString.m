function [including_names, just_values] = alphabeticalParameterString(func, x, xIsTransformed)
if nargin < 3
    xIsTransformed = false;
end
% alphabeticalParameterString(func, x)
% expands the vector x into the parameter configuration it stands for
% for categorical parameters the value with the appropriate index is used
% numerical parameters are rounded to four digits behind the comma

%=== Backtransform continuous parameters.
x=x(:);
if ~xIsTransformed
    x=config_back_transform(x', func)';
end
assert(all(~isnan(x)));

including_names = '';
just_values = '';
for i=1:func.dim
    if i>1
        including_names = [including_names ','];
        just_values = [just_values ','];
    end
    if ismember(i, func.cat)
        value = func.all_values{i}(x(i));
        value = value{1};
% the following is now done as part of config_back_transform            
%     else
%         %=== Round continuous parameters to 4 digits -- otherwise DB problems !
%         value = num2str(floor(x(i).*10000 + 0.5)/10000);
    else
        if func.is_integer_param(i)
            value = num2str(x(i));
        else
            value = num2str(x(i), '%.16f');
        end
    end
    tmp = func.param_names{i};
    if i == 1
        including_names = [tmp, '=', value];
        just_values = value;
    else
        including_names = [including_names, ' ', tmp, '=', value];
        just_values = [just_values, value];
    end
end
function orig_value = param_back_transform(transformed_value, transform_type)

switch transform_type
    case 0
        orig_value = transformed_value;
    case 1
        orig_value = exp(transformed_value);
    case 2 
        orig_value = 1-exp(transformed_value);
end
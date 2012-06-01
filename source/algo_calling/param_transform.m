function transformed_value = param_transform(orig_value, transform_type)

switch transform_type
    case 0
        transformed_value = orig_value;
    case 1
        transformed_value = log(orig_value);
    case 2
        transformed_value = -log(1-orig_value);
end
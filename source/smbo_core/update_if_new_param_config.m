function theta_idx = update_if_new_param_config(func,thetaNew,forsurenew_noparamstring)
    global ThetaUniqSoFar;
    global allParamStrings;

    if nargin < 3
        forsurenew_noparamstring = 0;
    end

    %=== Check if we have encountered the parameter configuration before.
    if ~forsurenew_noparamstring
        for theta_idx=1:size(ThetaUniqSoFar, 1)
            if all(ThetaUniqSoFar(theta_idx,:) == thetaNew)
                %=== Return index of known parameter configuration.
                return;
            end
        end
    end

    %=== New parameter configuration; construct parameter string.
    ThetaUniqSoFar = [ThetaUniqSoFar; thetaNew];
    newlen = size(ThetaUniqSoFar,1);
    if forsurenew_noparamstring
        allParamStrings{newlen} = '';
    else
        allParamStrings{newlen} = alphabeticalParameterString(func, thetaNew);
    end
    theta_idx = newlen;
end
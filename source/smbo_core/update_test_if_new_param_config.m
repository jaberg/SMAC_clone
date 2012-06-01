function theta_idx = update_test_if_new_param_config(func,thetaNew)
    global TestTheta;

    for theta_idx=1:size(TestTheta, 1)
        if all(TestTheta(theta_idx,:) == thetaNew)
            theta_idx = -theta_idx;
            return;
        end
    end

    TestTheta = [TestTheta; thetaNew];
    newlen = size(TestTheta,1);
    theta_idx = -newlen; % negative signalling these are only test configs
end
function model = smbo_runner(numRun, varargin)
% This is now just a wrapper around smbo.m, setting up the "function" to be optimized etc.

if nargin < 1 || mod(length(varargin),2)
    if isdeployed
        fprintf('\nUsage: smbo_runner numRun [plus many optional options, passed as <optname> <optvalue>]\n');
        fprintf('Examples:\n');
	fprintf('smbo_runner 0 model rf validN 10 scenario_file example_saps/scenario-Saps-single-QWH-instance.txt\n');
	fprintf('smbo_runner 0 model rf validN 10 scenario_file example_saps/scenario-Saps-SWGCP-sat-small-train-small-test.txt\n');
        fprintf('smbo_runner 0 model rf validN 10 scenario_file example_spear/scenario-Spear-SWGCP-sat-small-train-small-test.txt\n');   
        fprintf('smbo_runner 0 model rf validN 10 scenario_file example_spear/scenario-Spear-single-QWH-instance.txt\n');
    else
        fprintf('\nUsage: smbo_runner(numRun, [plus many optional options, passed as <optname>, <optvalue>])\n');
        fprintf('Examples:\n');
        fprintf('smbo_runner(0, ''model'', ''rf'', ''validN'', 10, ''scenario_file'', ''example_saps/scenario-Saps-single-QWH-instance.txt'')\n');
        fprintf('smbo_runner(0, ''model'', ''rf'', ''validN'', 10, ''scenario_file'', ''example_saps/scenario-Saps-SWGCP-sat-small-train-small-test.txt'')\n');
        fprintf('smbo_runner(0, ''model'', ''rf'', ''validN'', 10, ''scenario_file'', ''example_spear/scenario-Spear-SWGCP-sat-small-train-small-test.txt'')\n');   
        fprintf('smbo_runner(0, ''model'', ''rf'', ''validN'', 10, ''scenario_file'', ''example_spear/scenario-Spear-single-QWH-instance.txt'')\n');
    end
    fprintf('Exiting.\n\n');
    model = [];
    return;
end
if isdeployed
    numRun = str2double(numRun);
end    

outputstr = sprintf('Call in Matlab: smbo_runner(%d', numRun);
if ~isempty(varargin)
    outputstr = [outputstr, ', ', strjoin(varargin, ', ')];
end
outputstr = [outputstr, ')\n'];
fprintf(['\n', outputstr, '\n']);

outputstr = [outputstr, '\nCommand line call: smbo_runner ', to_s(numRun)];
for i=1:length(varargin)
    outputstr = [outputstr, ' ', to_s(varargin{i})];
end
outputstr = [outputstr, '\n'];

%% Process arguments pertaining configuration scenario.
[func, func_args_idxs] = process_func_arguments(varargin{:});

%% Process arguments pertaining configurator.
[options, opt_args_idxs] = parse_smbo_arguments(varargin{:});
options.seed = numRun;
if ~isfield(options, 'offline_validation')
    options.offline_validation = 1;
end

%% Verify command line options
parsed_args = union(find(func_args_idxs==1), find(opt_args_idxs==1));
unparsed_args = setdiff(1:length(varargin)/2, parsed_args);
if ~isempty(unparsed_args)
    error(['Unknown arguments: ', strjoin({varargin{unparsed_args*2-1}}, ', ')]);
end

%% For external algorithms: read in instances and seeds.
if func.external
    func = parse_inst_files(func, numRun, options.offline_validation);        
end

%% ============================= Run SMBO. ===============================
[min_x, min_val, bestconflist, model, incumbent_theta_idx, func, options] = smbo(func, options, outputstr);

% options.evalTimesIncumbents = 0;
%% Optional offline validation after SMBO finishes.
if (isfield(options, 'offline_validation') && options.offline_validation) || (isfield(options, 'evalTimesIncumbents') && options.evalTimesIncumbents)
	if ~func.external
		warning('offline_validation currently only supports external functions.')
	else
	    func.testFuncHandle = @(Theta_idx,instance_numbers,seeds,censorLimits) get_single_results(func, Theta_idx, seeds, func.test_instance_filenames(instance_numbers), censorLimits);
    	offline_validation(func, options, bestconflist, incumbent_theta_idx);
	end
end

%% DECLARATION OF ALL ANONYMOUS FUNCTIONS FOR MCC.
%#function covSum
%#function covDIFFard
%#function covDIFFiso
%#function covHybridSE_DIFFard
%#function covHybridSE_DIFFiso
%#function covHybridSE_DIFFiso_OnlyLen
%#function covHybridSE_DIFFiso_NoLen
%#function covHybridSE_DIFFiso_algo
%#function covMatern3iso
%#function covMatern5iso
%#function covNoise
%#function covSEard
%#function covSEiso
%#function covSum
%#function gpr
%#function gprCensor
%#function negLogCensoredConditional
%#function branin.m
%#function disc_bnet_ll
%#function disc_test_fun2
%#function disc_test_fun
%#function griewank
%#function hart6
%#function hartman6
%#function hartman6_marginalized
%#function hartman6_marginalized_t
%#function mixed_disc_cont_testfun
%#function prod_of_branins
%#function saved_saps_swgcp_first100train
%#function simplest_discrete
%#function sixHumpCamelBack
%#function eval_algo
%#function eval
%#function nmllModel
%#function crossValLL
%#function sample_exp_imp_forest
%#function gaussian_exp_imp_forest_m
%#function cmaes_fsphere
%#function cmaes_rastrigin
%#function cmaes_griewank
%#function cmaes_ackley
%#function cmaes323_sphere_10
%#function cmaes323_ackley_10
%#function cmaes323_griewank_10
%#function cmaes323_rastrigin_10
%#function cmaes323_bf1_10
%#function cmaes323_bf2_10
%#function cmaes323_bf3_10
%#function cmaes323_bf4_10
%#function cmaes323_bf5_10
%#function cmaes323_bf6_10
%#function cmaes323_bf7_10
%#function cmaes323_bf8_10
%#function cmaes323_bf9_10
%#function cmaes323_bf10_10
%#function cmaes323_bf11_10
%#function cmaes323_bf12_10
%#function benchmark_func
%#function benchmark_func_1
%#function benchmark_func_2
%#function benchmark_func_3
%#function benchmark_func_4
%#function benchmark_func_5
%#function benchmark_func_6
%#function benchmark_func_7
%#function benchmark_func_8
%#function benchmark_func_9
%#function benchmark_func_10
%#function benchmark_func_11
%#function benchmark_func_12
%#function regpoly0
%#function corrgauss
%#function cmaes

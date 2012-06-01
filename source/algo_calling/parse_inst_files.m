function func = parse_inst_files(func, numRun, do_offline_validation)
% Parse instance filenames to optimize external algorithm on.

if isfield(func, 'local_instance_seed_file_prefix')
    local_instance_seed_filename = parsePath([func.local_instance_seed_file_prefix, num2str(numRun), '.txt'], func.rootdir);
    [func.seeds, func.instance_filenames] = read_instances_and_seeds_rnd(local_instance_seed_filename);
    func.features = zeros(length(func.instance_filenames), 1);
end
if isfield(func, 'local_instance_file')
    func.instance_filenames = textread(func.local_instance_file,'%s%*[^\n]','delimiter',',');
    func.features = zeros(length(func.instance_filenames), 1);
end

if isfield(func, 'feature_file')
    func.feature_file = parsePath(func.feature_file, func.rootdir);
    func.names_in_feature_file=textread(func.feature_file,'%s%*[^\n]','delimiter',',');
    
    if ~isfield(func, 'instance_filenames')
        func.instance_filenames = func.names_in_feature_file;
    end
    try 
        func.features = csvread(func.feature_file,0,1); % if this is empty that's ok, then there are no features.
        fprintf('Using feature file %s\n', func.feature_file);
    catch  
        func.features = zeros(length(func.instance_filenames), 1);
        fprintf('No features given in file %s\n', func.feature_file);
    end
    
    %=== Bring the features into the right order. O(n^2) right now.
    if length(func.instance_filenames) > 1
        orig_names_in_feature_file = func.names_in_feature_file;
        orig_features = func.features;
        func.names_in_feature_file = {};
        func.features = [];
        for i=1:length(func.instance_filenames)
            for j=1:length(orig_names_in_feature_file)
                if strcmp(func.instance_filenames{i},orig_names_in_feature_file{j})
                    func.names_in_feature_file{end+1} = orig_names_in_feature_file{j};
                    func.features(end+1,:) = orig_features(j,:);
                    break;
                end
            end
        end
    end

    assert(length(func.instance_filenames)==length(func.names_in_feature_file));
    if length(func.instance_filenames)>1
        for i=1:length(func.instance_filenames)
            assert(strcmp(func.instance_filenames{i}, func.names_in_feature_file{i}));
        end
    end
else
    assert(isfield(func, 'local_instance_seed_file_prefix') || isfield(func, 'local_instance_file'), 'instance_seed_file or instance_file must be given if feature file is not given.');
end
func.numTrainingInstances = length(func.instance_filenames);

%% Make instance paths absolute.
if ~isfield(func, 'relativePaths') || ~func.relativePaths
    for i=1:func.numTrainingInstances
        func.instance_filenames{i} = parsePath(func.instance_filenames{i}, parsePath(func.rootdir, pwd));
    end
end

%% Prepare for offline validation. Doing this here to fail early, and not
%% only after the configuration run has finished.
if do_offline_validation
    rand('twister',numRun+1000000);
	randn('state',numRun+1000000);
    nTest = func.validN;
    if isfield(func, 'local_test_instance_seed_file') || isfield(func, 'local_test_instance_file')
        if isfield(func, 'local_test_instance_seed_file')
            %=== Read test instances and seeds.
            [func.test_seeds, func.test_instance_filenames] = read_seed_instance_file(parsePath(func.local_test_instance_seed_file, func.rootdir));
        else
            test_instance_filenames = textread(parsePath(func.local_test_instance_file, func.rootdir),'%s%*[^\n]','delimiter',',');
            func.test_instance_filenames = {};
            func.test_seeds = [];
            while length(func.test_instance_filenames) < nTest
                for i=1:length(test_instance_filenames)
                    func.test_instance_filenames{end+1} = test_instance_filenames{i};
                    func.test_seeds(end+1,1) = ceil((2^31-1)*rand);
                end
                if func.deterministic
                    break;
                end
            end
        end
        if length(func.test_seeds) > nTest
            func.test_seeds = func.test_seeds(1:nTest);
            func.test_instance_filenames = func.test_instance_filenames(1:nTest);
        end
        func.numTestInstances = length(func.test_instance_filenames);
        
        % Make test instance paths absolute.
		if ~isfield(func, 'relativePaths') || ~func.relativePaths
        	for i=1:func.numTestInstances
        	    func.test_instance_filenames{i} = parsePath(func.test_instance_filenames{i}, parsePath(func.rootdir, pwd));
	        end
		end
    end
    %=== We cannot yet construct the testFuncHandle, since we need to first
    %=== finish processFunc.
end
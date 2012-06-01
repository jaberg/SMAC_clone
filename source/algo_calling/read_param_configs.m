function param_index_matrix = read_param_configs(func, file, whole_traj_file, drop_first)
% Read N parameter settings in the .traj format (without the first 5 entries of .traj
% files unless whole_traj_file is set); return a N x func.dim matrix 
% containing transformed values for continuous
% parameters and indices for categorical parameters.
if nargin < 4
    drop_first = 0;
    if nargin < 3
        whole_traj_file=0;
    end
end

if exist(file)
    format_string = '';
    for i=1:func.dim-1
        format_string = strcat(format_string, '%[^,],');
    end
    if whole_traj_file
        for i=1:5
            format_string = strcat(format_string, '%[^,],');
        end
    end
    format_string = strcat(format_string, '%[^\n]');
    
    fid = fopen(file);
    data = textscan(fid, format_string, 'BufSize', 10000);
    
    if whole_traj_file
        data = data(6:end);
    end
    
%     %=== Special case: default-params
%     for k=1:length(data{1})
%         if strcmp(data{1}{k}, 'default-params')
%             for i=1:length(func.dim)
%                 if ismember(i, func.cat)
%                     data{k}{i} = func.all_values{i}{func.default_values(i)};
%                 else
%                     data{k}{i} = func.default_values(i);
%                 end
%             end
%         end
%     end
%     
    %=== Ensure ordering of data matches func.param_names.
    newdata = {};
    for i=1:length(data)
        name = data{i}{1};
        for j=1:length(func.param_names)
            if strcmp(func.param_names{j}, name)
                newdata{j} = data{i};
            end
        end
    end
    data = newdata;

    %=== Search for matching string in func.all_values, use the index of that.
    for i=1:length(data) % data{i} => {values of param i for each configuration}
        k_start = 2; % first entry is the header
        if drop_first
            k_start = 3;
        end

        if ismember(i, func.cat)
            for k=k_start:length(data{i}) % leaving out first item: default!
                idx = 0;
                for j=1:length(func.all_values{i})
                    if strcmp(func.all_values{i}{j}, num2str(data{i}{k}))
                        idx = j;
                        break;
                    end
                end
                assert(idx>0); % otherwise value doesn't exist
                param_index_matrix(k-k_start+1,i) = idx;
            end
        else
            for k=k_start:length(data{i})
                param_index_matrix(k-k_start+1,i) = str2num(data{i}{k});
            end
        end
    end
else
    param_index_matrix = [];
end

param_index_matrix = config_transform(param_index_matrix, func); % deal with the non-categorical parameters
if drop_first
    param_index_matrix = param_index_matrix(2:end,:);
end
function [seeds, filenames] = read_instances_and_seeds_rnd(filename)
% %=== Read in seeds and filenames from a seed_instance_file.
% %=== The %*[^\n] discards the rest of each line; without it we get an error
% [seeds, filenames] = textread(filename,'%d %s %*[^\n]');

tic;
filenames = textread(filename,'%s%*[^\n]', 'bufsize', 200000);
seeds = dlmread(filename, ' ', 0, 1);
read_inst_and_seed_time = toc

% data = textread(filename,'%s','delimiter', ' ');
% for i=1:length(data)
%     filenames{i} = data{i}(1);
%     seeds{i} = zeros(length(data{i})-1,1);
%     for j=2:length(data{i})
%         seeds{i}(j-1) = str2double(data{i}(j));
%     end
% end
function [seeds, filenames] = read_seed_instance_file(filename)
%=== Read in seeds and filenames from a seed_instance_file.
%=== The %*[^\n] discards the rest of each line; without it we get an error
[seeds, filenames] = textread(filename,'%d %s %*[^\n]');

% %=== Make solquals part of the filename; might break things if solqual does
% %not exist.
% It indeed broke things, and I do this withint the algorithm wrapper now.
% [seeds, filenames_tmp, solquals] = textread(filename,'%d %s %s %*[^\n]');
% filenames = filenames_tmp;
% for i=1:length(filenames_tmp)
%     filenames{i} = strcat([filenames_tmp{i}, ' ', solquals{i}]);
% end
% filenames

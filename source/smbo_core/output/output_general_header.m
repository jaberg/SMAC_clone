function output_general_header(header, options)
% OUTPUT FIRST GENERAL INFORMATION INTO LOG FILE.
bout(header, true);

alloptions = {};
for n = fieldnames(options)'
    alloptions{end+1} = char(n);
    alloptions{end+1} = options.(char(n));
end
bout(['\nAll options: ', strjoin(alloptions, ', '), '\n\n']);
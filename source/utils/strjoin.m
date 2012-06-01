function str = strjoin(cell, delim) %strjoin specific to SMBO options
    if isempty(cell) 
        str = '';
        return; 
    end
    if isnumeric(cell{1})
        str = num2str(cell{1});
    else
        if regexp(cell{1}, '^-?\d+(\.\d+)?$')
            str = cell{1};
        else
            str = ['''', cell{1}, ''''];
        end
    end
    for i=2:length(cell)
        if isnumeric(cell{i})
            str = [str, delim, num2str(cell{i})];
        else
            if regexp(cell{i}, '^-?\d+(\.\d+)?$')
                str = [str, delim, cell{i}];
            else
                str = [str, delim, '''', cell{i}, ''''];
            end
        end
    end
end
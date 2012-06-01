function path = parsePath(path, basepath)
    if isempty(basepath)
        error('basepath cannot be empty.');
    end
    if isempty(path)
        path = basepath;
    else
	if path(1) == '/'
	    % do nothing
	else
	    path = strcat(basepath, '/', path);
	end
    end
    path = regexprep(path, '\', '/');
    path = regexprep(path, '/+', '/');
    path = regexprep(path, '/(\./)+', '/');
    path = regexprep(path, '^(\./)+', '');
end

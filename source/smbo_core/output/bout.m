function bout(str, forceWriteToScreen)
if nargin < 2
    forceWriteToScreen = false; 
end
global log_fid
global writeToScreen
if ~isempty(log_fid)
    fprintf(log_fid, str);
end
if forceWriteToScreen || ~isempty(writeToScreen)
	fprintf(str);
end
function tout(str)
global log_fid
global traj_fid
global detailed_traj_fid
if ~isempty(log_fid)
    fprintf(log_fid, str);
end
if ~isempty(traj_fid)
    fprintf(traj_fid, str);
end
if ~isempty(detailed_traj_fid)
    fprintf(detailed_traj_fid, str);
end
fprintf(str);
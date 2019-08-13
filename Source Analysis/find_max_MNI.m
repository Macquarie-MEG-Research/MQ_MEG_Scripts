function [MNI_coord_of_max] = find_max_MNI(sourceI,template_grid,neurosynth)

if isfield(sourceI,'stat')
    d = find(sourceI.stat==max(sourceI.stat));
else
    
    try
        d = find(sourceI.pow==max(sourceI.pow));
    catch
        d = find(sourceI.avg.pow==max(sourceI.avg.pow));
    end
    
end

MNI_coord_of_max = template_grid.pos(d(1),:);


fprintf('Maximum MNI co-ordinates: %d %d %d\n',MNI_coord_of_max(1),...
    MNI_coord_of_max(2),MNI_coord_of_max(3));

if strcmp(neurosynth,'yes')
    disp('Going to neurosynth page of max co-ordinates');
    url = ['http://neurosynth.org/locations/' num2str(MNI_coord_of_max(1)) '_' ...
        num2str(MNI_coord_of_max(2)) '_' num2str(MNI_coord_of_max(3)) '/'];
    web(url,'-browser');
end
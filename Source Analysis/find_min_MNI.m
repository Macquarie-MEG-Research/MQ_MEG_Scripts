function [MNI_coord_of_max] = find_min_MNI(sourceI,template_grid,neurosynth)

if isfield(sourceI,'stat')
    d = find(sourceI.stat==min(sourceI.stat));
else
    
    try
        d = find(sourceI.pow==min(sourceI.pow));
    catch
        d = find(sourceI.avg.pow==min(sourceI.avg.pow));
    end
    
end

MNI_coord_of_max = template_grid.pos(d(1),:);


fprintf('Minimum MNI co-ordinates: %.0f %.0f %.0f\n',MNI_coord_of_max(1),...
    MNI_coord_of_max(2),MNI_coord_of_max(3));

if strcmp(neurosynth,'yes')
    disp('Going to neurosynth page of minimum co-ordinates');
    url = ['http://neurosynth.org/locations/' num2str(MNI_coord_of_max(1)) '_' ...
        num2str(MNI_coord_of_max(2)) '_' num2str(MNI_coord_of_max(3)) '/'];
    web(url,'-browser');
end
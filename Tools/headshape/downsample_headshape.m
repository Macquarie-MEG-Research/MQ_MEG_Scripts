function [headshape_downsampled] = downsample_headshape(path_to_headshape,...
    numvertices,varargin)

% If not specified include the facial points
if isempty(varargin)
    include_facial_points = 'yes';
    
else
    include_facial_points = varargin{1};
end


% Get headshape
headshape = ft_read_headshape(path_to_headshape);
% Convert to cm
headshape = ft_convert_units(headshape,'cm');
% Convert to BESA co-ordinates
%         headshape.pos = cat(2,fliplr(headshape.pos(:,1:2)),headshape.pos(:,3));
%         headshape.pos(:,2) = headshape.pos(:,2).*-1;

% Get indices of facial points (up to 3cm above nasion)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Is 3cm the correct distance?
% Possibly different for child system?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

count_facialpoints = find(headshape.pos(:,3)<3);
if isempty(count_facialpoints)
    disp('CANNOT FIND ANY FACIAL POINTS - COREG BY ICP MAY BE INACCURATE');
else
    facialpoints = headshape.pos(count_facialpoints,:,:);
    rrr = 1:4:length(facialpoints);
    facialpoints = facialpoints(rrr,:); clear rrr;
end

% Remove facial points for now
headshape.pos(count_facialpoints,:) = [];

% Create mesh out of headshape downsampled to x points specified in the
% function call
cfg.numvertices = numvertices;
cfg.method = 'headshape';
cfg.headshape = headshape.pos;
mesh = ft_prepare_mesh(cfg, headshape);

% Replace the headshape info with the mesh points
headshape.pos = mesh.pos;

% Create figure for quality checking
figure; subplot(2,2,1);ft_plot_mesh(mesh); hold on;
title('Downsampled Mesh');
view(0,0);
subplot(2,2,2);ft_plot_mesh(headshape); hold on;
title('Downsampled Headshape View 1');
view(0,0);
subplot(2,2,3);ft_plot_mesh(headshape); hold on;
title('Downsampled Headshape View 2');
view(90,0);
subplot(2,2,4);ft_plot_mesh(headshape); hold on;
title('Downsampled Headshape View 3');
view(180,0);
print('headshape_quality','-dpdf');

% Only include points facial points 2cm below nasion
rrr  = find(facialpoints(:,3) > -2);


% Add the facial points back in (default) or leave out if user specified
% 'no' in function call
if strcmp(include_facial_points,'yes')
    try
        % Add the facial info back in
        % Only include points facial points 2cm below nasion        
        headshape.pos = vertcat(headshape.pos,...
    facialpoints(find(facialpoints(:,3) > -2),:));
    catch
        disp('Cannot add facial info back into headshape');
    end
else
    headshape.pos = headshape.pos;
    disp('Not adding facial points back into headshape');
end

%Add in names of the fiducials from the sensor
headshape.fid.label = {'NASION','LPA','RPA'};

% Convert fiducial points to BESA
%         headshape.fid.pos = cat(2,fliplr(headshape.fid.pos(:,1:2)),headshape.fid.pos(:,3));
%         headshape.fid.pos(:,2) = headshape.fid.pos(:,2).*-1;

% Plot for quality checking
figure;%ft_plot_sens(sensors) %plot channel position : between the 1st and 2nd coils
ft_plot_headshape(headshape) %plot headshape
view(0,0);
print('headshape_quality2','-dpdf');

% Export filename
headshape_downsampled = headshape;

end
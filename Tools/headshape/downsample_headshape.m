function [headshape_downsampled] = downsample_headshape(path_to_headshape...
    ,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% headshape_downsampled: a function to downsample headshape information for
% more accurate coregistration. Typically the function will downsample
% headshape information to 200 scalp points, whilst preserving facial
% information (eyebrows, eye-sockets and nose)
%
% Designed for data from a Polhemus system
%
% Author: Robert Seymour (robert.seymour@mq.edu.au)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - path_to_headshape     = path to .hsp file
%
%%%%%%%%%%%%%%%%%%
% Variable Inputs:
%%%%%%%%%%%%%%%%%%
%
% - include_facial_points = 'yes' or 'no' (OPTIONAL - will remove any 
%                           facial info if set to 'no')
% - remove_zlim           = 'no', 'yes' or number (remove points which lie 
%                           Xcm above nasion on the z-axis
% - remove_below_nasion   = remove points which lie Xcm below nasion on the
%                           z-axis
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
%
% - downsampled_headshape = the downsampled headshape information

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if MQ_MEG_Scripts has been added to your MATLAB path

warning(['Needs further testing: is gridaverage or non-uniform',...
    'decimation better?']);

if exist('parsePolhemus') == 2
    disp('MQ_MEG_Scripts is in your MATLAB path :)')
else
    error(['Did you add all of MQ_MEG_Scripts to your MATLAB path? ',...
        'Download from ',...
        'https://github.com/Macquarie-MEG-Research/MQ_MEG_Scripts',...
        ' ...and type addpath(genpath(path_to_MQ_MEG_Scripts))']);
end

%% Start of function proper

% If not specified include the facial points
if isempty(varargin)
    include_facial_points   = 'yes';
    remove_zlim             = 'no';
    remove_below_nasion     = 2;
else
    include_facial_points = varargin{1};
    remove_zlim           = varargin{2};
    remove_below_nasion   = varargin{3};
    
    % If user specified 'yes' convert to default value
    if strcmp(remove_zlim,'yes')
        remove_zlim = 2.0;
    elseif isnumeric(remove_zlim)
        remove_zlim = remove_zlim;
    else
        ft_warning('NOT removing zlim. Please use a number e.g. 2.0');
        remove_zlim = 'no';
    end
    
    % If user specified 'no' make remove_below_nasion = 0
    if strcmp(remove_below_nasion,'no')
        remove_below_nasion = 0;
    
    % If user specified 'yes' make remove_below_nasion = 2
    elseif strcmp(remove_below_nasion,'yes')
        remove_below_nasion = 2;
    end
end

% Get headshape
headshape = ft_read_headshape(path_to_headshape);
% Convert to cm
headshape = ft_convert_units(headshape,'cm');
% Save a version for later
headshape_orig = headshape;

% Get indices of facial points (up to 3cm above nasion)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Is 3cm the correct distance?
% Possibly different for child system?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

count_facialpoints = find(headshape.pos(:,3)<3 & headshape.pos(:,1)>7);
if isempty(count_facialpoints)
    disp('CANNOT FIND ANY FACIAL POINTS - COREG BY ICP MAY BE INACCURATE');
else
    facialpoints = headshape.pos(count_facialpoints,:,:);
    rrr = 1:4:length(facialpoints);
    facialpoints = facialpoints(rrr,:); clear rrr;
end

% Remove facial points for now
headshape.pos(count_facialpoints,:) = [];

% Plot the facial and head points in separate colours
figure;
if isempty(count_facialpoints)
    disp('Not plotting any facial points')
else
    ft_plot_mesh(facialpoints,'vertexcolor','r','vertexsize',10); hold on;
end
ft_plot_mesh(headshape.pos,'vertexcolor','k','vertexsize',10); hold on;
view([90 0]);

% if the user specified to remove points along the zlim
if ~strcmp(remove_zlim,'no')
    
    % Also remove points Xcm above nasion
    points_below_X = find(headshape.pos(:,3) < remove_zlim);
    
    if isempty(points_below_X)
        disp('CANNOT FIND ANY POINTS LESS THAN the zlim specified');
    else
        
        % Remove these points
        headshape.pos(points_below_X,:) = [];
        
        % Plot the facial and head points in separate colours
        figure;
        ft_plot_mesh(headshape,'vertexcolor','r','vertexsize',10); hold on;
        
    end
end

% Create mesh out of headshape downsampled to x points specified in the
% function call
cfg = [];
%cfg.numvertices = 1000;
cfg.method = 'headshape';
cfg.headshape = headshape.pos;
mesh = ft_prepare_mesh(cfg, headshape);

%
[decimated_headshape] = decimate_headshape(headshape, 'gridaverage');

% Create figure for quality checking
figure; subplot(2,2,1);ft_plot_mesh(mesh,'facecolor','k',...
    'facealpha',0.1,'edgealpha',0); hold on;
ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
view(-180,0);
subplot(2,2,2);ft_plot_mesh(mesh,'facecolor','k',...
    'facealpha',0.1,'edgealpha',0); hold on;
ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
view(0,0);
subplot(2,2,3);ft_plot_mesh(mesh,'facecolor','k',...
    'facealpha',0.1,'edgealpha',0); hold on;
ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
view(90,0);
subplot(2,2,4);ft_plot_mesh(mesh,'facecolor','k',...
    'facealpha',0.1,'edgealpha',0); hold on;
ft_plot_mesh(headshape_orig.pos,'vertexcolor','r','vertexsize',2); hold on;
ft_plot_mesh(decimated_headshape,'vertexcolor','b','vertexsize',10); hold on;
view(-90,0);

print('headshape_quality','-dpng');

% Replace headshape.pos with decimated pos
headshape.pos = decimated_headshape;

% Only include points facial points 2cm below nasion
%rrr  = find(facialpoints(:,3) > -2);


% Add the facial points back in (default) or leave out if user specified
% 'no' in function call
if strcmp(include_facial_points,'yes')
    try
        % Add the facial info back in
        % Only include points facial points 2cm below nasion
        headshape.pos = vertcat(headshape.pos,...
            facialpoints(find(facialpoints(:,3) > -remove_below_nasion),:));
    catch
        disp('Cannot add facial info back into headshape');
    end
else
    headshape.pos = headshape.pos;
    disp('Not adding facial points back into headshape');
end

%Add in names of the fiducials from the sensor
headshape.fid.label = {'NASION','LPA','RPA'};

% Plot for quality checking

view_angle = [-180, 0]
figure;

for angle = 1:length(view_angle)
    subplot(1,2,angle)
    ft_plot_headshape(headshape,'vertexcolor','k','vertexsize',12) %plot headshape
    hold on;
    ft_plot_headshape(headshape_orig,'vertexcolor','r','vertexsize',2) %plot headshape
    view(view_angle(angle),10);
end

print('headshape_quality2','-dpng');


% Export filename
headshape_downsampled = headshape;
headshape_downsampled = ft_convert_units(headshape_downsampled,'mm');

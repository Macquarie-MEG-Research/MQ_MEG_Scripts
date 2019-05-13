%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% mq_coreg is a function to coregister a structural
% MRI with MEG data and associated headshape information
%
% Author: Robert Seymour (May 2019) robert.seymour@mq.edu.au
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - dir_name                = directory name for the output of your coreg
% - mri_file                = full path to the NIFTI structural MRI file
% - scalpthreshold          = threshold for scalp extraction 
%                           (try 0.05 if unsure)
% - headshape_downsampled   = downsampled headshape information
%
%%%%%%%%%%%%%%%%%%
% Variable Inputs:
%%%%%%%%%%%%%%%%%%
%
% - weight_number           = (OPTIONAL) how strongly do you want to weight  
%                           the facial points (0-1)? DEFAULT = 0.8
% - sourcemodel_size        = (OPTIONAL) grid size in mm (5,8,10)
%                           DEFAULT = 8
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs (saved to dir_name):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - mri_realigned           = the mri realigned based on fiducial points
% - trans_matrix            = transformation matrix for accurate coregistration
% - mri_realigned2          = the coregistered mri based on ICP algorithm
% - headmodel               = coregistered singleshell headmodel
% - sourcemodel3d           = sourcemodel warped to MNI space
%

% EXAMPLE FUNCTION CALL:
% mq_coreg(dir_name,mri_file,0.05,headshape_downsampled,0.8,8)

% THIS IS A WORK IN PROGRESS FUNCTION - any updates or suggestions would be
% much appreciated
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mq_coreg(dir_name,grad_trans,mri_file,...
    scalpthreshold,headshape_downsampled,varargin)

if isempty(varargin)
    weight_number       = 0.8;
    sourcemodel_size    = 8;
else
    weight_number       = 1./varargin{1};
    sourcemodel_size    = varargin{2};
end

cd(dir_name); disp('CDd to the right place');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display function information
disp(['mq_coreg.m version May 2019. Remember to add MQ_MEG_Scripts',...
    'to your search path']);

%% Cd to correct place
cd(dir_name); fprintf('\nCDd to the right place\n');

%% Load in MRI
disp('Reading the MRI file');
mri_orig = ft_read_mri(mri_file); % in mm, read in mri from DICOM
mri_orig = ft_convert_units(mri_orig,'mm');
mri_orig.coordsys = 'neuromag';

% MRI...
% Give rough estimate of fiducial points
cfg                         = [];
cfg.method                  = 'interactive';
cfg.viewmode                = 'ortho';
cfg.coordsys                = 'bti';
[mri_realigned]             = ft_volumerealign(cfg, mri_orig);

disp('Saving the first realigned MRI');

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_realigned, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_headshape(headshape_downsampled);

%% Extract Scalp Surface
cfg = [];
cfg.output    = 'scalp';
cfg.scalpsmooth = 5;
cfg.scalpthreshold = scalpthreshold;
scalp  = ft_volumesegment(cfg, mri_realigned);

%% Create mesh out of scalp surface
cfg = [];
cfg.method = 'isosurface';
cfg.numvertices = 10000;
mesh = ft_prepare_mesh(cfg,scalp);
mesh = ft_convert_units(mesh,'mm');

figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none',...
    'facealpha',0.8); drawnow;

%% Create Figure for Quality Checking

figure;
ft_plot_mesh(mesh,'facecolor',[238,206,179]./255,'EdgeColor','none','facealpha',0.8); hold on;
camlight; lighting phong; camlight left; camlight right; material dull
hold on; drawnow;
view(90,0);
ft_plot_headshape(headshape_downsampled); drawnow;
title('If this looks weird you might want to adjust the cfg.scalpthreshold value');
print('mesh_quality','-dpng');


%% Perform ICP using mesh and headshape information
numiter = 50;
disp('Performing ICP fit with 50 iterations\n');

% Weight the facial points x10 times higher than the head points
count_facialpoints2 = find(headshape_downsampled.pos(:,3)<3); x = 1;

% If there are no facial points ignore the weighting
if isempty(count_facialpoints2)
    w = ones(size(headshape_downsampled.pos,1),1).*1;
    weights = @(x)assignweights(x,w);
    disp('NOT Applying Weighting\n');
    % But if there are facial points apply weighting using weight_number
else
    w = ones(size(headshape_downsampled.pos,1),1).*weight_number;
    w(count_facialpoints2) = 1;
    weights = @(x)assignweights(x,w);
    fprintf('Applying Weighting of %.2f \n',weight_number);
end

% Now try ICP with weights
[R, t, err] = icp(mesh.pos', headshape_downsampled.pos', numiter, ...
    'Minimize', 'plane', 'Extrapolation', true, 'Weight', weights,...
    'WorstRejection', 0.05);

%% Create figure to display how the ICP algorithm reduces error
clear plot;
figure; plot([1:1:51]',err,'LineWidth',8);
ylabel('Error'); xlabel('Iteration');
title('Error*Iteration');
set(gca,'FontSize',25);

%% Create transformation matrix
trans_matrix = inv([real(R) real(t);0 0 0 1]);

%% Create figure to assess accuracy of coregistration
mesh_spare = mesh;
mesh_spare.pos = ft_warp_apply(trans_matrix, mesh_spare.pos);
c = datestr(clock); %time and date

figure;
ft_plot_mesh(mesh_spare,'facecolor',[238,206,179]./255,'EdgeColor','none','facealpha',0.8); hold on;
camlight; lighting phong; camlight left; camlight right; material dull; hold on;
ft_plot_headshape(headshape_downsampled); title(sprintf('%s.   Error of ICP fit = %d' , c, err(end)));
clear c; print('ICP_quality','-dpng');


%% Apply transform to the MRI
mri_realigned2 = ft_transform_geometry(trans_matrix,mri_realigned);

% check that the MRI is consistent after realignment
ft_determine_coordsys(mri_realigned2, 'interactive', 'no');
hold on; % add the subsequent objects to the figure
drawnow; % workaround to prevent some MATLAB versions (2012b and 2014b) from crashing
ft_plot_headshape(headshape_downsampled);

%% Segment
disp('Segmenting the brain');
cfg           = [];
cfg.output    = 'brain';
mri_segmented  = ft_volumesegment(cfg, mri_realigned2);

%% Create singleshell headmodel
disp('Creating a singleshell headmodel');
cfg = [];
cfg.method='singleshell';
headmodel = ft_prepare_headmodel(cfg, mri_segmented); % in mm, create headmodel

%% Create Sourcemodel (in mm)
fprintf('Creating an %dmm Sourcemodel in mm\n',sourcemodel_size);

cfg                = [];
cfg.grid.warpmni   = 'yes';
cfg.grid.resolution = sourcemodel_size;
cfg.grid.nonlinear = 'yes'; % use non-linear normalization
cfg.mri            = mri_realigned2;
cfg.grid.unit      ='mm';
cfg.inwardshift    = -1.5;
sourcemodel3d      = ft_prepare_sourcemodel(cfg);

% Create figure to check headodel and sourcemodel match
figure;
ft_plot_vol(headmodel,  'facecolor', 'cortex', 'edgecolor', 'none');
alpha 0.4; camlight;
ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:),'vertexsize',5);
view([0 0]);

view_angle = [0 90 180 270];

%% Create figure to show final coregiration
figure; hold on;
for rep = 1:4
    subplot(2,2,rep);
    ft_plot_vol(headmodel,  'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.6; camlight;
    ft_plot_mesh(sourcemodel3d.pos(sourcemodel3d.inside,:),'vertexsize',3);
    ft_plot_sens(grad_trans, 'style', 'r*')
    ft_plot_headshape(headshape_downsampled) %plot headshape
    view([view_angle(rep),0]);
    ft_plot_mesh(mesh_spare,'facecolor',[238,206,179]./255,'EdgeColor','none','facealpha',0.5);
    camlight; lighting phong; material dull;
end

print('coregistration_volumetric_quality_check','-dpng','-r100');

%% Save relevent information
disp('Saving the necessary data');
save headmodel headmodel
save mri_realigned mri_realigned
save trans_matrix trans_matrix
save mri_realigned2 mri_realigned2
save sourcemodel3d sourcemodel3d
save trans_matrix trans_matrix
end
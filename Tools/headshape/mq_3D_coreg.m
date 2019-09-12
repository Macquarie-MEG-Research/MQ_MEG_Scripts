function mq_3D_coreg(varargin)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mq_3D_coreg
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mode 1: specify all options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - dir_name     = directory for saving
% - path_to_obj  = full path to the .obj file
% - scaling      = scale the coil location down by X% (e.g. 0.96 = 4%
%                scaling down)
%
%%%%%%%%%%%%%%%%%%%%%%%%%
% Mode 2: specify scaling
%%%%%%%%%%%%%%%%%%%%%%%%%
% - scaling      = scale the coil location down by X% (e.g. 0.96 = 4%
%                scaling down)
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
%
% - grad_trans              = sensors transformed to correct
% - shape                   = headshape and fiducial information
% - headshape_downsampled   = headshape downsampled to 100 points
% - trans_matrix            = transformation matrix applied to headmodel
%                           and sourcemodel
% - sourcemodel3d           = sourcemodel warped to MNI space
% - headmodel               = singleshell headmodel (10000 vertices)
%
%%%%%%%%%%%%%%%%%%%%%
% Other Information:
%%%%%%%%%%%%%%%%%%%%%



%% Check inputs
% If user has no inputs --> open dialogue box so they can select the
% relevent file (.obj or /zip). Scaling is set to 1 (i.e. no scaling)

if length(varargin) == 0
    scaling = 1;
    [filename,dir_name] = uigetfile({'*'});
    path_to_obj = [dir_name filename];
    
    % If user has one input --> open dialogue box so they can select the
    % relevent file (.obj or /zip)
elseif length(varargin) == 1
    scaling = varargin{1};
    [filename,dir_name] = uigetfile({'*'});
    
    path_to_obj = [dir_name filename];
    
    % If user has three inputs --> use these
elseif length(varargin) == 3
    dir_name    = varargin{1};
    path_to_obj = varargin{2};
    scaling     = varargin{1};
    
    % Check inputs:
    % If dir_name doesn't end with / or \ throw up and error
    if ismember(dir_name(end),['/','\']) == 0
        error('!!! dir_name must end with / or \ !!!');
    end
    
else
    ft_error('Incorrect number of inputs specified');
end

%%
% Cd to the dir_name
cd(dir_name);

% If the input file is .zip --> UNZIP!
if strcmp(path_to_obj(end-3:end),'.zip')
    disp('Unzipping...');
    unzip(path_to_obj,dir_name)
    path_to_obj = [dir_name 'Model.obj'];
    
end
    
% Load in data 
head_surface = ft_read_headshape(path_to_obj);
head_surface = ft_convert_units(head_surface,'mm');

% Mark fiducials on headsurface
cfg = [];
cfg.channel = {'Nasion','Left PA','Right PA'};
cfg.method = 'headshape';
fiducials = ft_electrodeplacement(cfg,head_surface);

% Convert to BTI space
cfg = [];
cfg.method = 'fiducial';
cfg. coordsys = 'bti';
cfg.fiducial.nas    = fiducials.elecpos(1,:); %position of NAS
cfg.fiducial.lpa    = fiducials.elecpos(2,:); %position of LPA
cfg.fiducial.rpa    = fiducials.elecpos(3,:); %position of RPA
head_surface_bti    = ft_meshrealign(cfg,head_surface);

% Save fiducial information in BTI space
transform_bti = ft_headcoordinates(cfg.fiducial.nas, ...
    cfg.fiducial.lpa, cfg.fiducial.rpa, cfg.coordsys);

fids_for_mesh = ft_warp_apply(transform_bti,fiducials.elecpos);

% Plot figure 
figure;
set(gcf,'Position',[100 100 1000 600]);
subplot(1,2,1);
ft_plot_axes(head_surface_bti);
ft_plot_mesh(head_surface_bti);
view([0,0]);
subplot(1,2,2);
ft_plot_axes(head_surface_bti);
ft_plot_mesh(head_surface_bti);
view([90,0]);
print('FIDS','-dpng','-r200');

% 
cfg = [];
cfg.channel = {'LPAred','RPAyel','PFblue','LPFwh','RPFblack'};
cfg.method = 'headshape';
markers_from_headshape = ft_electrodeplacement(cfg,head_surface_bti);

% Shrink by 5% to compensate for markers
markers_from_headshape2 = markers_from_headshape;
    markers_from_headshape2.chanpos = ft_warp_apply([scaling 0 0 0;...
        0 scaling 0 0; 0 0 scaling 0; 0 0 0 1],...
        markers_from_headshape2.chanpos);
   
    % Make figure
    color_array = [1 0 0; 1 1 0; 0 0 1; 0 1 1; 0 0 0];
    
    %Make figure;
    figure;
    ft_plot_mesh(head_surface_bti,'facealpha',0.6);
    ft_plot_mesh(markers_from_headshape2.chanpos,'vertexsize',...
        20,'vertexcolor',color_array);
    
%% Downsample headshape    
disp('Downsampling headshape');    
head_surface_bti.faces = head_surface_bti.tri;
head_surface_bti.vertices = head_surface_bti.pos;
V = reducepatch(head_surface_bti,0.05);

head_surface_decimated = head_surface_bti;
head_surface_decimated = rmfield(head_surface_bti,'tri');
head_surface_decimated.pos = V.vertices;
%head_surface_decimated.tri = V.faces;
head_surface_decimated = rmfield(head_surface_decimated,{'faces',...
    'vertices','color'});

if size(head_surface_decimated.pos,1) > 10000
    ft_warning('Downsampling headshape further');
    head_surface_bti.faces = head_surface_bti.tri;
    head_surface_bti.vertices = head_surface_bti.pos;
    V = reducepatch(head_surface_bti,0.025);
    
    head_surface_decimated = head_surface_bti;
    head_surface_decimated.pos = V.vertices;
    %head_surface_decimated.tri = V.faces;
    head_surface_decimated = rmfield(head_surface_decimated,{'faces',...
        'vertices','color'});
end

disp('Removing points 2cm below nasion on the z-axis');
points_below_nasion = find(head_surface_decimated.pos(:,3)<-20);

head_surface_decimated.pos(points_below_nasion,:) = [];

try
    figure; ft_plot_mesh(head_surface_bti); alpha 0.3;
    ft_plot_mesh(head_surface_decimated); camlight;
    
    view([0,0]);
    
catch
    disp('could not plot');
end

%% Now we need to create a dummy .elp file to read into MEG160

disp('Writing .elp file');

elp = fopen('test.elp.elp', 'wt');

fids_for_mesh2 = round((fids_for_mesh./1000),4);
markers_from_headshape3 = round((markers_from_headshape2.chanpos./1000),4);

fprintf(elp,['3	2\n//Probe file\n//Minor revision number\n1\n'...
    '//ProbeName\n']);
fprintf(elp,'%s\n','%N	Name');
fprintf(elp,['//Probe type, number of sensors\n0	5\n'...
    '//Position of fiducials X+, Y+, Y- on the subject\n']);
fprintf(elp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(1,1),...
    fids_for_mesh2(1,2),fids_for_mesh2(1,3));
fprintf(elp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(2,1),...
    fids_for_mesh2(2,2),fids_for_mesh2(2,3));
fprintf(elp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(3,1),...
    fids_for_mesh2(3,2),fids_for_mesh2(3,3));
fprintf(elp,'//Sensor type\n');
fprintf(elp,'%s\n','%S	1C00');
fprintf(elp,'//Sensor name and data for sensor # 1\n');
fprintf(elp,'%s\n','%N	LPAred  ');
fprintf(elp,'%.4f	%.4f	%.4f\n',markers_from_headshape3(1,1),...
    markers_from_headshape3(1,2),markers_from_headshape3(1,3));
fprintf(elp,'//Sensor type\n');
fprintf(elp,'%s\n','%S	1C00');
fprintf(elp,'//Sensor name and data for sensor # 2\n');
fprintf(elp,'%s\n','%N	RPAyel  ');
fprintf(elp,'%.4f	%.4f	%.4f\n',markers_from_headshape3(2,1),...
    markers_from_headshape3(2,2),markers_from_headshape3(2,3));
fprintf(elp,'//Sensor type\n');
fprintf(elp,'%s\n','%S	1C00');
fprintf(elp,'//Sensor name and data for sensor # 3\n');
fprintf(elp,'%s\n','%N	PFblue  ');
fprintf(elp,'%.4f	%.4f	%.4f\n',markers_from_headshape3(3,1),...
    markers_from_headshape3(3,2),markers_from_headshape3(3,3));
fprintf(elp,'//Sensor type\n');
fprintf(elp,'%s\n','%S	1C00');
fprintf(elp,'//Sensor name and data for sensor # 4\n');
fprintf(elp,'%s\n','%N	LPFwh  ');
fprintf(elp,'%.4f	%.4f	%.4f\n',markers_from_headshape3(4,1),...
    markers_from_headshape3(4,2),markers_from_headshape3(4,3));
fprintf(elp,'//Sensor type\n');
fprintf(elp,'%s\n','%S	1C00');
fprintf(elp,'//Sensor name and data for sensor # 5\n');
fprintf(elp,'%s\n','%N	RPFblack  ');
fprintf(elp,'%.4f	%.4f	%.4f\n',markers_from_headshape3(5,1),...
    markers_from_headshape3(5,2),markers_from_headshape3(5,3));

fclose(elp);

%% Now we need to create a dummy .hsp file to read into MEG160
disp('Writing .hsp file');

hsp = fopen('test.hsp.hsp', 'wt');

pos_dec = round((head_surface_decimated.pos./1000),4);

fids_for_mesh2 = round((fids_for_mesh./1000),4);
markers_from_headshape3 = round((markers_from_headshape2.chanpos./1000),4);

fprintf(hsp,['3	200\n//Shape file\n//Minor revision number\n2\n'...
    '//ProbeName\n']);
fprintf(hsp,'%s\n','%N	Name');
fprintf(hsp,'//Shape code, number of digitized points\n0	%d\n',...
    length(pos_dec));
fprintf(hsp,'//Position of fiducials X+, Y+, Y- on the subject\n');
fprintf(hsp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(1,1),...
    fids_for_mesh2(1,2),fids_for_mesh2(1,3));
fprintf(hsp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(2,1),...
    fids_for_mesh2(2,2),fids_for_mesh2(2,3));
fprintf(hsp,'%s	%.4f	%.4f	%.4f\n','%F',fids_for_mesh2(3,1),...
    fids_for_mesh2(3,2),fids_for_mesh2(3,3));
fprintf(hsp,'//No of rows, no of columns; position of digitized points\n');
fprintf(hsp,'%d	3\n ',length(pos_dec));

for i = 1:length(pos_dec)
    fprintf(hsp,'%.4f	%.4f	%.4f\n',pos_dec(i,1),pos_dec(i,2),...
        pos_dec(i,3));
end
fclose(hsp);


end







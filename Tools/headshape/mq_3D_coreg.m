function mq_3D_coreg(cfg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mq_3D_coreg: a function designed for the user to mark the location of
% the head-position indicator (or 'marker') coils on a 3D .obj object file,
% captured using the Ipad-based Structure Sensor. A downsampled .hsp file
% and .elp file are produced.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%
% cfg options:
%%%%%%%%%%%%%%%
% - cfg.dir_name         = directory for saving
% - cfg.path_to_obj      = full path to the .obj or .zip file
% - cfg.scaling          = scale the coil location down by X% (e.g. 0.96 = 4%
%                        scaling down)
% - cfg.subject_number   = subject number for MEG (e.g. '1234');
% - cfg.subject_initials = subject initials (e.g. 'RS')
% - cfg.project_number   = MEG project nuber (e.g. '123')
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
% XXXX_XX_MEXXX_yyyy_mm_dd.elp.elp   = .elp file
% XXXX_XX_MEXXX_yyyy_mm_dd.hsp.hsp   = .hsp file
%
%%%%%%%%%%%
% Other:
%%%%%%%%%%%
% If cfg.dir_name or cfg.path_to_obj is not specified, a GUI is presented
% for the user to select the relevent .obj or .zip file. The results are
% then saved in the current directory
% 
%%%%%%%%%%%%%%%%%%%%%%%%
% Example Function Call:
%%%%%%%%%%%%%%%%%%%%%%%%
% cfg                  = [];
% cfg.subject_number   = '1111';
% cfg.subject_intials  = 'RS';
% cfg.project_number   = '176';
% cfg.scaling          = 0.98;
% mq_3D_coreg(cfg)

%% Display
disp('mq_3D_coreg (v1.0) written by Robert Seymour, 2019');
ft_warning('Make sure you are using a version of Fieldtrip later than August 2019');

%% Check inputs

% Get function cfg
dir_name            = ft_getopt(cfg,'dir_name',[]);
scaling             = ft_getopt(cfg,'scaling',1);
path_to_obj         = ft_getopt(cfg,'path_to_obj',[]);
subject_number      = ft_getopt(cfg,'subject_number','XXXX');
subject_initials    = ft_getopt(cfg,'subject_initials','XX');
project_number      = ft_getopt(cfg,'project_number','XXX');

% If no dir_name or path_to_obj specified let the user select with GUI
if isempty(dir_name) || isempty(path_to_obj)
    [filename,dir_name] = uigetfile({'*'});
    path_to_obj = [dir_name filename];
end

% Check input:
% If dir_name doesn't end with / or \ throw up and error
if ismember(dir_name(end),['/','\']) == 0
    error('!!! cfg.dir_name must end with / or \ !!!');
end

%%
% Cd to the dir_name
cd(dir_name);

%% Deal with .zips (If the input file is .zip --> UNZIP!)
if strcmp(path_to_obj(end-3:end),'.zip')
    disp('Unzipping...');
    unzip(path_to_obj,dir_name)
    path_to_obj = [dir_name 'Model.obj'];
end

%% What should the .output files be called?
try
file_out_name = [subject_number '_' subject_initials '_ME' ...
    project_number '_' datestr(now,'yyyy_mm_dd')];
catch
    file_out_name = 'XXXX';
end

%% Start of function proper
% Load in data
try
    disp('Loading .obj file. This takes around 10 seconds');
    head_surface = ft_read_headshape(path_to_obj);
catch
   disp('Did you download a version of Fieldtrip later than August 2019?');
end
    
%head_surface.color = head_surface.color./255;
head_surface = ft_convert_units(head_surface,'mm');

% Mark fiducials on headsurface
try
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_RS(cfg,head_surface);
catch
    % Most likely the user will not have ft_electrodeplacement_RS in the
    % right location. Try to correct this
    disp('Trying to move ft_electrodeplacement_RS to the Fieldtrip directory');
    [ftver, ftpath] = ft_version();
    loc_of_ft_elecRS = which('ft_electrodeplacement_RS2');
    copyfile(loc_of_ft_elecRS,ftpath);
    
    % Rename ft_electrodeplacement_RS2 to ft_electrodeplacement_RS
    movefile(fullfile(ftpath,'ft_electrodeplacement_RS2.m'),...
        fullfile(ftpath,'ft_electrodeplacement_RS.m'));
    
    cfg = [];
    cfg.channel = {'Nasion','Left PA','Right PA'};
    cfg.method = 'headshape';
    fiducials = ft_electrodeplacement_RS(cfg,head_surface);
end

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
try
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
print([file_out_name '_FIDS' ],'-dpng','-r200');
catch
    disp('Could not plot')
end

% Mark the location of the marker (or HPI) coils
cfg = [];
cfg.channel = {'LPAred','RPAyel','PFblue','LPFwh','RPFblack'};
cfg.method = 'headshape';
markers_from_headshape = ft_electrodeplacement_RS(cfg,head_surface_bti);

% Shrink by X% to compensate for markers
markers_from_headshape2 = markers_from_headshape;
markers_from_headshape2.chanpos = ft_warp_apply([scaling 0 0 0;...
    0 scaling 0 0; 0 0 scaling 0; 0 0 0 1],...
    markers_from_headshape2.chanpos);

% Make figure
color_array = [1 0 0; 1 1 0; 0 0 1; 0 1 1; 0 0 0];

try
    figure;
    views = [0 0; 90 90];
    
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    for i = 1:2
        subplot(1,2,i)
        ft_plot_mesh(head_surface_bti,'facealpha',0.4);
        ft_plot_mesh(markers_from_headshape2.chanpos,'vertexsize',...
            20,'vertexcolor',color_array);
        view(views(i,:));
    end
    print([file_out_name '_coil_locations'],'-dpng','-r200');
catch
    disp('Could not display figure');
end

%% Downsample headshape

disp('Downsampling headshape');
head_surface_bti.faces = head_surface_bti.tri;
head_surface_bti.vertices = head_surface_bti.pos;
V = reducepatch(head_surface_bti,0.05);
T = reducepatch(head_surface_bti,0.2);

% For non-facial points
head_surface_decimated = head_surface_bti;
head_surface_decimated = rmfield(head_surface_bti,'tri');
head_surface_decimated.pos = V.vertices;
%head_surface_decimated.tri = V.faces;
head_surface_decimated = rmfield(head_surface_decimated,{'faces',...
    'vertices','color'});

% For facial points
head_surface_decimated2 = head_surface_bti;
head_surface_decimated2 = rmfield(head_surface_bti,'tri');
head_surface_decimated2.pos = T.vertices;
%head_surface_decimated.tri = V.faces;
head_surface_decimated2 = rmfield(head_surface_decimated2,{'faces',...
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

%% Deal with facial points
% This is all hard-coded based on a few participants. Perhaps in the 
% future the user could specify these options? Anyway they're kept large,
% and the user can use downsample_headshape_new to trim.

count_facialpoints = find(head_surface_decimated2.pos(:,3)<20 ...
    & head_surface_decimated2.pos(:,3)>-80 ...
    & head_surface_decimated2.pos(:,1)>20 ...
    & head_surface_decimated2.pos(:,2)<70 ...
    & head_surface_decimated2.pos(:,2)>-70);
if isempty(count_facialpoints)
    disp('CANNOT FIND ANY FACIAL POINTS - COREG BY ICP MAY BE INACCURATE');
else
    facialpoints = head_surface_decimated2.pos(count_facialpoints,:,:);
    rrr = 1:4:length(facialpoints);
    facialpoints = facialpoints(rrr,:); clear rrr;
end

% Remove facial points for now
head_surface_decimated2.pos(count_facialpoints,:) = [];
hs_spare = head_surface_decimated2;

%% Remove Points 2cm above the nasion
disp('Removing points 2cm above nasion on the z-axis');

points_below_nasion = head_surface_decimated.pos(:,3)< 20;

head_surface_decimated.pos(points_below_nasion,:) = [];
hs_spare2 = head_surface_decimated;

%% Add the facial points back in
if ~isempty(facialpoints)
    try
        % Add the facial info back in
        % Only include points facial points 2cm below nasion
        head_surface_decimated.pos = vertcat(head_surface_decimated.pos,...
            facialpoints);
    catch
        disp('Cannot add facial info back into headshape');
    end
else
    disp('Not adding facial points back into headshape');
end

%% Create a Figure to Show the Downsampling Process
% Plot the facial and head points in separate colours
try
    figure;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    
    subplot(2,2,1);
    ft_plot_mesh(facialpoints,'vertexcolor','r','vertexsize',10); hold on;
    ft_plot_mesh(head_surface_bti); alpha 0.3; camlight;
    title({'Facial Points are'; 'Marked in Red'});
    view([90 0]);
    subplot(2,2,2);
    ft_plot_mesh(head_surface_bti); alpha 0.3;
    ft_plot_mesh(hs_spare2,'vertexcolor','b','vertexsize',10); camlight;
    title({'Selected Scalp'; 'Points'});
    view([0,0]);
    subplot(2,2,3);
    ft_plot_mesh(head_surface_decimated);
    ft_plot_mesh(head_surface_bti); alpha 0.3; camlight;    
    title({'Final Mesh'});
    view([0,0]);
    subplot(2,2,4);
    ft_plot_mesh(head_surface_decimated);
    ft_plot_mesh(head_surface_bti); alpha 0.3; camlight;
    title({'Final Mesh'});
    view([90,0]);
    print([file_out_name '_downsampled'],'-dpng','-r200');
catch
    disp('Could not plot');
end

%% Now we need to create a dummy .elp file to read into MEG160

disp('Writing .elp file');

elp = fopen([file_out_name '.elp'], 'wt');

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

hsp = fopen([file_out_name '.hsp'], 'wt');

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







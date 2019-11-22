%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% mq_preprocessing_example.m 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Set up paths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Path to the raw data (make sure this ends with /)
data_path   = '/Volumes/Robert T5/sample_data/';

% Path to where the data should be saved (make sure this ends with /)
save_path   = '/Volumes/Robert T5/sample_data_processed/';

% Path to MQ_MEG_Scripts
% Download from https://github.com/Macquarie-MEG-Research/MQ_MEG_Scripts
path_to_MQ_MEG_Scripts = '/Users/rseymoue/Documents/GitHub/MQ_MEG_Scripts/';

% Path to MEMES
% Download from https://github.com/Macquarie-MEG-Research/MEMES
path_to_MEMES = '/Users/rseymoue/Documents/GitHub/MEMES/';

% Path to MRI Library for MEMES
path_to_MRI_library = '/Volumes/Robert T5/new_HCP_library_for_MEMES/';

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Add MQ_MEG_Scripts and MEMES to path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Adding MQ_MEG_Scripts and MEMES to your MATLAB path');
warning(['Please note that MQ_MEG_Scripts and MEMES are designed for'...
    ' MATLAB 2016b or later and have been tested using Fieldtrip'...
    ' version 20181213']);
addpath(genpath(path_to_MQ_MEG_Scripts));
addpath(genpath(path_to_MEMES));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Specifiy Subject ID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subject = '3566';

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Make a subject specific results folder for saving
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Making subject specific folder for saving');

% Get the path to the saving directory
dir_name = [save_path subject];
% Make the directory!
mkdir(dir_name);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Specify paths to confile, mrkfile, elpfile and hspfile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

confile = [data_path 'sub-' subject '/ses-1/meg/sub-' subject...
    '_ses-1_task-alien_run-1_meg.con'];

mrkfile = [data_path 'sub-' subject...
    '/ses-1/meg/sub-' subject '_ses-1_task-alien_run-1_markers.mrk'];

elpfile = dir([data_path 'sub-' subject...
    '/ses-1/extras/*.elp']);
elpfile = [elpfile.folder '/' elpfile.name];

hspfile = dir([data_path 'sub-' subject...
    '/ses-1/extras/*.hsp']);
hspfile = [hspfile.folder '/' hspfile.name];

% Get the path to the saving directory
dir_name = [save_path subject];
cd(dir_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Check for saturations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[sat] = mq_detect_saturations(dir_name,confile)
save sat sat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7. Downsample Headshape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

headshape_downsampled = downsample_headshape(hspfile,'yes',0);
figure; ft_plot_headshape(headshape_downsampled);

% Save
cd(dir_name);
disp('Saving headshape_downsampled');
save headshape_downsampled headshape_downsampled;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8. Realign Sensors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[grad_trans] = mq_realign_sens(dir_name,elpfile,hspfile,...
    confile,mrkfile,'','rot3dfit');

print('grad_trans','-dpng','-r200');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9. Read in raw MEG data & apply filters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Running Preprocessing Script for Project ME176 - Alien Task');

% CD to correct directory
cd(dir_name);

% Epoch the whole dataset into one continous dataset and apply
% the appropriate filters
cfg = [];
cfg.headerfile = confile;
cfg.datafile = confile;
cfg.trialdef.triallength = Inf;
cfg.trialdef.ntrials = 1;
cfg = ft_definetrial(cfg)

cfg.continuous = 'yes';
alldata = ft_preprocessing(cfg);

% Band-pass filter between 0.5-250Hz to help visualisation
cfg.continuous = 'yes';
cfg.bpfilter = 'yes';
cfg.bpfreq = [0.5 250];
alldata = ft_preprocessing(cfg);

% Deal with 50Hz line noise using a bandstop filter
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq = [49.5 50.5];
alldata = ft_preprocessing(cfg,alldata);

% Deal with 100Hz line noise using a bandstop filter
cfg = [];
cfg.bsfilter = 'yes';
cfg.bsfreq = [99.5 100.5];
alldata = ft_preprocessing(cfg,alldata);

% Create layout file for later and save
cfg             = [];
cfg.grad        = alldata.grad;
lay             = ft_prepare_layout(cfg, alldata);
save lay lay

% Cut out MEG channels
cfg = [];
cfg.channel = alldata.label(1:160);
alldata = ft_selectdata(cfg,alldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 10. Epoch the data into trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cfg = [];
cfg.dataset                 = confile;
cfg.continuous              = 'yes';
cfg.trialdef.prestim        = 2.0;         % pre-stimulus interval
cfg.trialdef.poststim       = 2.0;        % post-stimulus interval
cfg.trialfun                = 'mytrialfun_MQ_grating';
data_raw                    = ft_definetrial(cfg);

% Redefines the filtered data
cfg = [];
data = ft_redefinetrial(data_raw,alldata);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 11. Visually Inspect data for "bad" trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cfg                 = [];
cfg.channel         = {'MEG','-AG001','-AG002','-AG068'};
cfg.colorgroups     = 'allblack';
cfg.viewmode        = 'vertical';
cfg.plotevents      = 'no'; 
ft_databrowser(cfg,data)

% Load the summary again so you can manually remove any bad trials
cfg             = [];
cfg.method      = 'summary';
cfg.keepchannel = 'yes';
grating         = ft_rejectvisual(cfg, data);
clear data

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 12. Perform ICA & Remove ECG/EOG artefacts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Downsample Data
grating_orig    = grating; %save the original CLEAN data for later use 
cfg             = []; 
cfg.resamplefs  = 150; %downsample frequency 
cfg.detrend     = 'no'; 
disp('Downsampling data');
grating            = ft_resampledata(cfg, grating_orig);

% Run ICA
disp('About to run ICA using the Runica method')
cfg                 = [];
cfg.method          = 'fastica';
cfg.numcomponent    = 50;
cfg.feedback        = 'textbar';
comp                = ft_componentanalysis(cfg, grating);

% Display Components - change layout as needed
cfg             = []; 
cfg.compscale   = 'local';
cfg.viewmode    = 'component'; 
cfg.layout      = lay;
cfg.position    = [1 1 800 700];
cfg.ylim        = [ -2.8015e-11  5.7606e-11 ];
cfg.blocksize   = 4;
ft_databrowser(cfg, comp);

ft_hastoolbox('brewermap',1);
colormap123     = colormap(flipud(brewermap(64,'RdBu')));

cfg             = [];
cfg.layout      = lay;
cfg.blocksize   = 4;
cfg.zlim        = 'maxabs';
cfg.colormap    = colormap123;
[rej_comp]      = ft_icabrowser(cfg, comp);

% Decompose the original data as it was prior to downsampling 
disp('Decomposing the original data as it was prior to downsampling...');
cfg           = [];
cfg.unmixing  = comp.unmixing;
cfg.topolabel = comp.topolabel;
comp_orig     = ft_componentanalysis(cfg, grating_orig);

%% The original data can now be reconstructed, excluding specified components
% This asks the user to specify the components to be removed
disp('Enter components in the form [1 2 3]')
comp2remove     = input('Which components would you like to remove?\n');
cfg             = [];
cfg.component   = [comp2remove]; %these are the components to be removed
data_clean      = ft_rejectcomponent(cfg, comp_orig,grating_orig);

%% Plot the Clean Data
cfg = [];
cfg.channel         = {'MEG','-AG001','-AG002','-AG068'};
cfg.colorgroups     = 'allblack';
cfg.viewmode        = 'vertical';
cfg.plotevents      = 'no'; 
ft_databrowser(cfg,data_clean);




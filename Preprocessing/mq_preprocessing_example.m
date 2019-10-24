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

headshape_downsampled = downsample_headshape(hspfile,'yes',2);
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
cfg.trialdef.poststim       = 3.0;        % post-stimulus interval
cfg.trialfun                = 'mytrialfun_new_alien';
data_raw                    = ft_definetrial(cfg);

% Redefines the filtered data
cfg = [];
data = ft_redefinetrial(data_raw,alldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 11. Epoch the data into trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%








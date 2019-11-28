
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% meg_mri_coreg_tutorial.m 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Add Relevent Paths

% Path to the Fieldtrip Toolbox
path_to_fieldtrip       = '/Users/rseymoue/Documents/GitHub/fieldtrip';
 
% Path to MQ_MEG_Scripts
path_to_MQ_MEG_Scripts  = '/Users/rseymoue/Documents/GitHub/MQ_MEG_Scripts/';

% Path to MEMES
path_to_MEMES           = '/Users/rseymoue/Documents/GitHub/MEMES/';

% Path to the MRI library used for MEMES (adult)
path_to_MRI_library     = '/Volumes/Robert T5/new_HCP_library_for_MEMES/';

% Path to the structural MRI;
path_to_MRI             = '/Users/rseymoue/Documents/test_RS/RS.nii';

% Add Fieldtrip
addpath(path_to_fieldtrip);
ft_defaults;

% Add MQ_MEG_Scripts
addpath(genpath(path_to_MQ_MEG_Scripts));

% Add MEMES & Specify 
addpath(genpath(path_to_MEMES));


%% Polhemus with Subject's Structural MRI
% Load grad_trans.mat (output from mq_realign_sens)
load('grad_trans.mat');

% Downsample headshape
cfg                         = [];
cfg.downsample_facial_info  = 'yes';
cfg.facial_info_below_z     = 20;
hsp                         = downsample_headshape_new(cfg,...
    '0000_RS_polhemusVSiPad_2018_12_18.hsp');

% Perform coreg
mq_coreg(cd,grad_trans,path_to_MRI,0.05,hsp,0.1,8)
clear hsp

%% Polhemus with MEMES
% Load grad_trans.mat (output from mq_realign_sens)
load('grad_trans.mat');

% Downsample headshape
cfg                         = [];
cfg.downsample_facial_info  = 'yes';
cfg.facial_info_below_x     = 60;
cfg.facial_info_below_z     = 20;
hsp                         = downsample_headshape_new(cfg,...
    '0000_RS_polhemusVSiPad_2018_12_18.hsp');

% MEMES
MEMES3(cd,grad_trans,hsp,path_to_MRI_library,'average',1,8,3);

clear hsp

%% Structure Sensor with Subject's Structural MRI
% Load headshape (no downsampling)
hsp     = ft_read_headshape('0000_XX_MEXX_2019_11_27.hsp.hsp');
hsp     = ft_convert_units(hsp,'mm');

% Perform Coreg
mq_coreg_ipad(cd,'RS.nii',0.05,hsp,8);

clear hsp

%% Structure Sensor with MEMES
% Load grad_trans.mat (output from mq_realign_sens)
load('grad_trans.mat');

% Downsample Headshape
cfg                         = [];
cfg.downsample_facial_info  = 'yes';
cfg.facial_info_below_x     = 60;
cfg.facial_info_below_z     = 20;
hsp                         = downsample_headshape_new(cfg,...
    '0000_XX_MEXX_2019_11_27.hsp.hsp');

% MEMES
MEMES3(cd,grad_trans,hsp,path_to_MRI_library,'average',1,8,3);






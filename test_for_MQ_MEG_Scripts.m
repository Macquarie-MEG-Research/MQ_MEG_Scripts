%%
% This is a test script for Robert in order to test adult MEG data pipeline
% with example data. Paths specific for RS.

subject_mine = '3076';

addpath(genpath('/Users/44737483/Documents/scripts_mcq/MQ_MEG_Scripts'));

dir_name = ['/Users/44737483/Documents/MMN_data/' subject_mine '/'];
cd(dir_name);

% Load information about the file name
load('/Users/44737483/Documents/mcq_data/d.mat');

% Confile
confile = ['/Users/44737483/Documents/mcq_data/' subject_mine '/meg/run-MMN-no-noise/'...
    eval(sprintf('d.file_name_%s',subject_mine)) '_mmn_nonoise.con'];

% Mrkfile
mrkfile = ['/Users/44737483/Documents/mcq_data/' subject_mine '/meg/run-MMN-no-noise/'...
    eval(sprintf('d.file_name_%s',subject_mine)) '_mmn_nonoise_PRE.mrk'];

% Elpfile
elpfile = ['/Users/44737483/Documents/mcq_data/' subject_mine '/meg/'...
    eval(sprintf('d.file_name_%s',subject_mine)) '.elp'];

% hspfile
hspfile = ['/Users/44737483/Documents/mcq_data/' subject_mine '/meg/'...
    eval(sprintf('d.file_name_%s',subject_mine)) '.hsp'];

% niifile
mri_file = ['/Users/44737483/Documents/mcq_data/' subject_mine '/anat/'...
    subject_mine '.nii'];

%% Test downsample_headshape

headshape_downsampled = downsample_headshape(hspfile);

%% Test mq_realign_sens

bad_coil = '';
method = 'rot3dfit';

[grad_trans] = mq_realign_sens(dir_name,elpfile,hspfile,confile,mrkfile,...
    bad_coil,method)

%% Test coreg
mq_coreg(dir_name,grad_trans,mri_file,0.05,headshape_downsampled)




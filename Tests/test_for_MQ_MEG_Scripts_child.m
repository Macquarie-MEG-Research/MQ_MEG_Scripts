%%
% This is a test script for Robert in order to test child MEG data pipeline
% with example data. Paths specific for RS.

% Subject Number
subject_mine = '2683';

% Add MQ_MEG_Scripts
addpath(genpath('/Users/44737483/Documents/scripts_mcq/MQ_MEG_Scripts'));

%% Specific variables
% Specific directory location
dir_name = ['/Users/44737483/Documents/best_MMN/' subject_mine '/ReTHM'];
cd(dir_name);

% Confile
confile = [dir_name '/2683_AL_ME125_2017_09_15_B1_denoise_rethm.con'];

% Mrkfile
mrkfile = [dir_name '/2683_AL_ME125_2017_09_15_INI.mrk'];

% Elpfile
elpfile = [dir_name '/2683_AL_ME125_2017_09_15.elp'];

% hspfile
hspfile = [dir_name '/2683_AL_ME125_2017_09_15.hsp']

%% Test get_reTHM_data
bad_coil = '';
[head_movt] = get_reTHM_data(dir_name,confile,grad_trans...
    ,headshape_downsampled, bad_coil)

%% Test downsample_headshape

headshape_downsampled = downsample_headshape_child(hspfile)

%% Test mq_realign_sens

bad_coil = '';
method = 'icp';

mq_realign_sens(dir_name,elpfile,hspfile,confile,mrkfile,...
    bad_coil,method)

%% Test child_MEMES

path_to_MRI_library = '/Users/44737483/Documents/scripts_mcq/MRIDataBase_JohnRichards_USC/database_for_MEMES_child/';

child_MEMES(dir_name,grad_trans,headshape_downsampled,...
    path_to_MRI_library)





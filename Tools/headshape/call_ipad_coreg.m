
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Add Fieldtrip and MQ_MEG_Scripts to your MATLAB path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

path_to_MQ_MEG_Scripts = '';
path_to_FT_toolbox     = '';

disp('Adding Fieldtrip to your MATLAB path');
addpath(path_to_FT_toolbox);
ft_defaults

disp('Adding MQ_MEG_Scripts to your MATLAB path');
addpath(genpath(path_to_MQ_MEG_Scripts));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Change your Current Directory to where you want the .elp and .hsp file
%    to be saved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd('');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Call mq_3D_coreg 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cfg                 = [];
cfg.subject_number  = '1111';
cfg.subject_intials  = 'RS';
cfg.project_number  = '176';
cfg.scaling         = 0.98;
mq_3D_coreg(cfg)


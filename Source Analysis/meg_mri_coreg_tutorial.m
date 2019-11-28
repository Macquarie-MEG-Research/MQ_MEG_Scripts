
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% meg_mri_coreg_tutorial.m 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Polhemus with 

%% Structure Sensor with Subject's Structural MRI
hsp = ft_read_headshape('0000_XX_MEXX_2019_11_27.hsp.hsp');
hsp = ft_convert_units(hsp,'mm');

mq_coreg_ipad(cd,'RS.nii',0.05,hsp,8);

clear hsp

%% Structure Sensor with MEMES

cfg = [];
cfg.downsample_facial_info = 'yes';
cfg.facial_info_below_x = 60;
cfg.facial_info_below_z = 20;
hsp = downsample_headshape_new(cfg,'0000_XX_MEXX_2019_11_27.hsp.hsp');

MEMES3(cd,grad_trans,hsp,path_to_MRI_library,'average',1,8,3);






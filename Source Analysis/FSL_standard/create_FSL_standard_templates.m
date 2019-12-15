%% Create template headmodel and sourcemodel from FSL Standard Brain
cd('/Users/rseymoue/Documents/GitHub/MQ_MEG_Scripts/Source Analysis/FSL_standard');

template            = ft_read_mri('MNI152_T1_1mm_brain.nii.gz');
template.coordsys   = 'fsl';

% segment the template brain and construct a volume conduction model (i.e. head model):
% this is needed to describe the boundary that define which dipole locations are 'inside' the brain.
cfg          = [];
template_seg = ft_volumesegment(cfg, template);

cfg                 = [];
cfg.method          = 'singleshell';
template_headmodel  = ft_prepare_headmodel(cfg, template_seg);
% Convert the vol to cm
template_headmodel  = ft_convert_units(template_headmodel, 'mm'); 

% construct the dipole grid in the template brain coordinates
% the negative inwardshift means an outward shift of the brain surface for inside/outside detection

res = [2 5 8 10];

for i = 2:length(res)
    
    cfg              = [];
    cfg.resolution   = res(i);
    cfg.tight        = 'yes';
    cfg.inwardshift  = -1.5;
    cfg.headmodel    = template_headmodel;
    cfg.spmversion     = 'spm12';   % default is 'spm8'
    cfg.spmmethod      = 'new';      % default is 'old'
    template_grid    = ft_prepare_sourcemodel(cfg);
    
    % make a figure with the template head model and dipole grid
    figure
    hold on
    ft_plot_headmodel(template_headmodel, 'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;
    ft_plot_mesh(template_grid.pos(template_grid.inside,:));
    title([res(i) ' mm']);
    
    save(['template_grid_' num2str(res(i)) 'mm'], 'template_grid');
    clear template_grid
end

save template_headmodel template_headmodel

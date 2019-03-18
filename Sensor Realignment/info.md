### If you have all 5 markers working use this code:

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A script to realign the MEG sensors based on the position of the 5 marker
% coils

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load raw data
cfg = [];
cfg.dataset = datafile;
cfg.continuous   = 'yes';
data_raw = ft_preprocessing(cfg);

%% Get information from the Polhemus files
parsePolhemus(elpfile,hspfile);
load shape; % in mm, the headshape and fiducial data from the polhemus 
shape                       = ft_convert_units(shape,'cm');
save shape shape

%% Calculation transformation matrix
grad_con                    = data_raw.grad; %in cm, load grads
mrk                         = ft_read_headshape(mrkfile,'format','yokogawa_mrk');
markers                     = mrk.fid.pos([2 3 1 4 5],:);%reorder mrk to match order in shape
[R,T,Yf,Err]                = rot3dfit(markers,shape.fid.pnt(4:end,:));%calc rotation transform
meg2head_transm             = [[R;T]'; 0 0 0 1];%reorganise and make 4*4 transformation matrix

%% Transform
grad_trans                  = ft_transform_geometry_PFS_hacked(meg2head_transm,grad_con); %Use my hacked version of the ft function - accuracy checking removed not sure if this is good or not
grad_trans.fid              = shape; %add in the head information
save grad_trans grad_trans

%% Make figure for quality checking
hfig = figure;
subplot(2,2,1);ft_plot_headshape(shape); 
hold on; ft_plot_sens(grad_trans); view([180, 0]);
subplot(2,2,2);ft_plot_headshape(shape); 
hold on; ft_plot_sens(grad_trans); view([-90, 0]);
subplot(2,2,3);ft_plot_headshape(shape); 
hold on; ft_plot_sens(grad_trans); view([0, 0]);
hax = subplot(2,2,4);ft_plot_headshape(shape);
hold on; ft_plot_sens(grad_trans); view([90, 0]);

saveas(gcf,'shape.png','png');
```

### If you have one bad marker coil use this variation:

```matlab
% shape = output of parsePolhemus.m
% data_raw = MEG data from ft_preprocessing
% mrkfile = mrkfile (duh)  

bad_coil = '' % name of the coil as desribed in parsePolhemus.m (LPAred/RPAyel/PFblue/LPFwh/RPFblack)

fprintf(''); disp('TAKING OUT BAD MARKER');

% Identify the bad coil
badcoilpos = find(ismember(shape.fid.label,bad_coil));

% Take away the bad marker
marker_order = [2 3 1 4 5];

grad_con                    = data_raw.grad; %in cm, load grads
mrk                         = ft_read_headshape(mrkfile,'format','yokogawa_mrk');
markers                     = mrk.fid.pos(marker_order,:);%reorder mrk to match order in shape

% Now take out the bad marker when you realign
markers(badcoilpos-3,:) = [];
fids_2_use = shape.fid.pnt(4:end,:); fids_2_use(badcoilpos-3,:) = [];
[R,T,Yf,Err]                = rot3dfit(markers,fids_2_use);%calc rotation transform
meg2head_transm             = [[R;T]'; 0 0 0 1];%reorganise and make 4*4 transformation matrix

grad_trans                  = ft_transform_geometry_PFS_hacked(meg2head_transm,grad_con);
grad_trans.fid              = shape; %add in the head information
save grad_trans grad_trans
```


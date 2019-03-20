function get_reTHM_data(dir_name,confile,grad_trans,headshape_downsampled)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MRI Estimation for MEG Sourcespace (MEMES)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - dir_name                = directory for saving
% - confile                 = path to con file
% - grad_trans              = MEG sensors information read in with
%                           ft_read_sens and realigned using 
%                           MQ_MEG_Scripts tools
% - headshape_downsampled   = headshape read in with ft_read_headshape and
%                           downsampled to around 100 scalp points
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
%
% - GOF.png = Goodness of Fit Plot
% - mrk_over_time_grad_trans.png
% - movt_mrk_time.png
% - rotations.png
% - translations.png

%%%%%%%%%%%%%%%%%%%%%
% Other Information:
%%%%%%%%%%%%%%%%%%%%%

% Example function call:
% get_reTHM_data(dir_name,confile,headshape_downsampled)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Show function call and submit warnings
disp('get_reTHM_data v0.1');
ft_warning('Cannot cope with bad markers yet');

% CD to right place
cd(dir_name);

% Read reTHM data from .con file (Channel 192)
try
    head_movt = read_reTHM(confile);
catch
    disp('Did you add MQ_MEG_Scripts/tools to your MATLAB path?')
    disp(['Download from https://github.com/',...
        'Macquarie-MEG-Research/MQ_MEG_Scripts'])
    disp('If you did... I cannot read reTHM data from the .con file');
end

%% Show goodness of fit

disp('Calculating Goodness of Fit for the 5 markers');

mrk_colors = ['r','y','b','w','k'];

figure;

for i = 1:5
    plot(head_movt.time,head_movt.gof(:,i),mrk_colors(i),'LineWidth',3); 
    hold on;
end

% Set colors
%set(gcf,'Color',[0.5,0.5,0.5]);
set(gca,'Color',[0.7,0.7,0.7]);
set(gcf, 'InvertHardcopy', 'off')
ylabel('Goodness of Fit (0-1)');
xlabel('Time (Sec)')
set(gca,'FontSize',20);

% If there is low goodness of fit change the axes
if min(min(head_movt.gof(:,:))) > 0.98
    ylim([0.98 1.0]);
else
     ylim([min(min(head_movt.gof(:,:))) 1.0]);
end

print('GOF.png','-dpng','-r300');

%% Create figure to show how far participant moved across whole recording
%  In relation to MEG sensors

load('grad_trans.mat');
figure; ft_plot_sens(grad_trans,'edgealpha',0.2);

for i = 1:5

    ft_plot_mesh(squeeze(head_movt.pos(:,i,:))...
        ,'vertexcolor',mrk_colors(i));
end

view([90,0]);
print('mrk_over_time_grad_trans.png','-dpng','-r300');

%% Quantify this movement in reference to the first marker measurement

disp(['Calculating absolute movement in relation to the first',...
    ' marker measurement']);

movt = [];

for i = 1:5
    for j = 1:length(head_movt.pos)
        movt(i,j) = pdist2(squeeze(head_movt.pos(1,i,:))',...
            squeeze(head_movt.pos(j,i,:))');
    end
end
    
figure;
% For every marker
for i = 1:5
    % Plot the head movt over time
    plot(head_movt.time,movt(i,:),...
        mrk_colors(i),'LineWidth',2); hold on;
    
    fprintf('Max Movement for %8s: %.4fmm\n',head_movt.label{i},...
        max(movt(i,:))); 
    
end

% Set colors
set(gca,'Color',[0.7,0.7,0.7]);
set(gcf, 'InvertHardcopy', 'off')
ylabel('Movement (mm)');
xlabel('Time (Sec)')
set(gca,'FontSize',20);

% If there is high movement change the axes
if max(max(movt(:,:))) < 10

    ylim([0 10]);
else
     ylim([0 max(max(movt(:,:)))]);
end

print('movt_mrk_time.png','-dpng','-r300');

%% Now calculate rotation and translation?

% This is a little hacky, but what I did was to transform the fiducial
% coordinates based on rotation/translation matrix between first marker
% position and every other marker position.

% This replictates the format Fieldtrip likes (3 'coils') from CTF data.

% Using this we can use the circumcenter function from Stolk et al., 2012 
% to obtain translation and rotation values at each time point. 
% There is probably a more sreamlined way to do this... but I want to
% follow the Fieldtrip tutorial as closely as I can...

disp('Calculating rotation and translation...');
disp('in relation to first marker measurement');

% Load headshape + fiducial information
fiducials_over_time = [];

for i = 1:length(head_movt.pos);
    try
    [R,T,Yf,Err]    = rot3dfit(squeeze(head_movt.pos(1,:,:)),...
            squeeze(head_movt.pos(i,:,:)));%calc rotation transform
    meg2head_transm = [[R;T]'; 0 0 0 1];%reorganise and make 4*4 transformation matrix
                
    fiducials_over_time(i,:,:,:) = ft_warp_apply(meg2head_transm,...
    headshape_downsampled.fid.pos);
    catch
        fiducials_over_time(i,:,:,:) = nan(3);
    end
end
 
% Use circumcenter function to determine the position and orientation of 
% the circumcenter of the three fiducial markers 

[cc] = circumcenter(squeeze(fiducials_over_time(:,:,1))',...
    squeeze(fiducials_over_time(:,:,2))',...
    squeeze(fiducials_over_time(:,:,3))');

% Compute circumcenter relative to the first marker
cc_rel = [cc - repmat(cc(:,1),1,size(cc,2))]';

%cc_dem = [cc - repmat(nanmean(cc,2),1,size(cc,2))]';

% Plot translations
col_for_figs = [0.2,0.2,0.2;0.55,0.55,0.55;0.9,0.9,0.9];
direction = {'x','y','z'};

figure;
for i = 1:3
    plot(head_movt.time,cc_rel(:,i),'Color',col_for_figs(i,:),...
        'LineWidth',3); hold on;
    
    fprintf('Absolute maximum movement in %s: %.4fmm\n',...
        direction{i},max(abs(cc_rel(:,i))));
end

disp('Plotting translations');
title({'Translation in mm';'x=dark, y=middle, z=light'});
ylabel('Movement (mm)');
xlabel('Time (Sec)')
set(gca,'FontSize',20);
print('translations.png','-dpng','-r300');


% Plot Rotations
disp('Plotting rotations');
figure;
for i = 1:3
    plot(head_movt.time,cc_rel(:,i+3),'Color',col_for_figs(i,:),...
        'LineWidth',3); hold on;
    
    fprintf('Absolute maximum rotation in %s: %.4fmm\n',...
        direction{i},max(abs(cc_rel(:,i+3))));
end

title({'Rotation in mm';'x=dark, y=middle, z=light'});
ylabel('Movement (mm)');
xlabel('Time (Sec)')
set(gca,'FontSize',20);
print('rotations.png','-dpng','-r300');

end







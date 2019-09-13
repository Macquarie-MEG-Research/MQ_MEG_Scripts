function [head_movt,confound] = get_reTHM_data(dir_name,confile,grad_trans...
    ,path_to_headshape, bad_coil, gof_value)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get_reTHM_data: function to read reTHM (head movement) data from a .con
% file. Designed for data from Yokogawa MEG160 MEG system.
%
% Author: Robert Seymour (robert.seymour@mq.edu.au)
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
% - path_to_headshape       = path to .hsp file
% - bad_coil                = list of bad coils (up to length of 2). 
%                           Enter as: {'LPAred','RPAyel','PFblue',...
%                           'LPFwh','RPFblack'}
% - gof_value               = goodness of fit threshold for rejecting 
%                           reTHM data. Try 0.99 in the first instance.
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
%
% - head_movt   = structure with reTHM data, time and goodness of fit 
%               information 
% - confound    = matrix of rotations (x,y,z) and translations (x,y,z)
%               which can be used with ft_regressconfound
%
% - GOF.png     = Goodness of Fit Plot
% - mrk_over_time_grad_trans.png
% - movt_mrk_time.png
% - rotations.png
% - translations.png

%%%%%%%%%%%%%%%%%%%%%
% Other Information:
%%%%%%%%%%%%%%%%%%%%%

% Example function call:
% get_reTHM_data(dir_name,confile,headshape_downsampled,'',0.99)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Show function call and submit warnings
disp('get_reTHM_data v0.1');
ft_warning('Cannot cope with 2 bad markers yet');
assert(length(bad_coil)<3,['You need at least 3 good coils for',...
    'accurate alignment\n']);

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

% Read headshape data from hsp file
headshape = ft_read_headshape(path_to_headshape);
headshape = ft_convert_units(headshape,'mm');

%% Remove bad_coils

mrk_colors = ['r','y','b','w','k'];

if strcmp(bad_coil,'')
    
else
    for coil = 1:length(bad_coil)
        fprintf('Removing %s coil\n',bad_coil{coil});
        find_bad_coil_pos = find(ismember(head_movt.label,bad_coil{coil}));
        
        head_movt.label(find_bad_coil_pos) = [];
        head_movt.pos(:,find_bad_coil_pos,:) = [];
        head_movt.gof(:,find_bad_coil_pos) = [];
        mrk_colors(find_bad_coil_pos) = [];
    end
end

%% Show goodness of fit

disp('Calculating Goodness of Fit for the 5 markers');

figure;

for i = 1:size(head_movt.pos,2)
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
ylim([0.98 1.0]);

print('GOF.png','-dpng','-r300');


% Remove data contaminated by bad GOF
[row,~] = find(head_movt.gof < gof_value);

% Only return unique values
row = unique(row);

% If there are any bad GOF times replace the data with NaNs and replot
if ~isempty(row)
    
    ft_warning('Replacing reTHM data with NaNs for times with bad gof values');
    
    for r = 1:length(row)
        head_movt.pos(row(r),:,:) = NaN;
        head_movt.gof(row(r),:,:) = NaN;
    end
    
    figure;
    
    for i = 1:size(head_movt.pos,2)
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
    ylim([gof_value 1.0]);
    print('GOF_corrected.png','-dpng','-r300');
end

%% Calculate NaNs and correct
for i = 1:size(head_movt.pos,2)
    num_of_nans = sum(isnan(squeeze(head_movt.pos(:,i,1))));
    perc_of_nans = ((length(head_movt.pos)-num_of_nans)...
        ./length(head_movt.pos)).*100;
    
    % Show warning if over 10%... if not show actual percetnage
    if 100-perc_of_nans > 10
        fprintf('Percentage NaNs for %8s: %.3f BAD MARKER?\n',...
            head_movt.label{i},100-perc_of_nans);
        ft_warning('BAD MARKER?');
        pause(1.0);
    else
        fprintf('Percentage NaNs for %8s: %.3f\n',head_movt.label{i},...
            100-perc_of_nans)
    end
end

% This is a very very simple NaN correction - filling in with the previous
% entry. If the first/last entry is missing the nearest available value is
% used. We could make it more complicated.. but I guess this will do for
% now.

disp('Correcting NaNs');

for i = 1:size(head_movt.pos,2)
    for j = 1:size(head_movt.pos,3)
        head_movt.pos(:,i,j) = fillmissing(head_movt.pos(:,i,j),...
            'previous','EndValues','nearest');
    end
end

%% Create figure to show how far participant moved across whole recording
%  In relation to MEG sensors

figure; ft_plot_sens(grad_trans,'edgealpha',0.2);

for i = 1:size(head_movt.pos,2)

    ft_plot_mesh(squeeze(head_movt.pos(:,i,:))...
        ,'vertexcolor',mrk_colors(i));
end

view([90,0]);
print('mrk_over_time_grad_trans.png','-dpng','-r300');

%% Quantify this movement in reference to the first marker measurement

disp(['Calculating absolute movement in relation to the first',...
    ' marker measurement']);

movt = [];

for i = 1:size(head_movt.pos,2)
    for j = 1:length(head_movt.pos)
        movt(i,j) = pdist2(squeeze(head_movt.pos(1,i,:))',...
            squeeze(head_movt.pos(j,i,:))');
    end
end
    
figure;
% For every marker
for i = 1:size(head_movt.pos,2)
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

fprintf(['Calculating rotation and translation in relation to first'...
    ' marker measurement...\n']);

% Load headshape + fiducial information
fiducials_over_time = [];

% If there are 5 good markers use rot3dfit to transform fiducials
if length(head_movt.label) > 4
    method_for_transform = 'rot3dfit';
    disp('Using method: rot3dfit ... Please wait...');
    % Otherwise use icp
else
    method_for_transform = 'icp';
    disp('Using method: ICP ... Please wait...');
end

ft_progress('init', 'text', 'Please wait...')

% for each marker measurement
for i = 1:length(head_movt.pos)
    try
        switch method_for_transform
            
            case 'rot3dfit'
                % Display the progress of the function
                ft_progress(i, 'Processed %d of %d reTHM measurements',i,...
                    length(head_movt.pos));
                
                [R,T,Yf,Err]    = rot3dfit(squeeze(head_movt.pos(1,:,:)),...
                    squeeze(head_movt.pos(i,:,:)));%calc rotation transform
                meg2head_transm = [[R;T]'; 0 0 0 1];
                %reorganise and make 4*4 transformation matrix
                
            case 'icp'
                % Display the progress of the function
                ft_progress(i, 'Processed %d of %d reTHM measurements',i,...
                    length(head_movt.pos));
    
                [R, T, err, dummy, info]    = icp(squeeze(head_movt.pos(1,:,:))',...
                    squeeze(head_movt.pos(i,:,:))',50,'Minimize', 'point');
                meg2head_transm             = [[R T]; 0 0 0 1];
        end
        
        fiducials_over_time(i,:,:,:) = ft_warp_apply(meg2head_transm,...
            headshape.fid.pos);
        
    catch
        fiducials_over_time(i,:,:,:) = nan(3);
    end
end
ft_progress('close');


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

% Export trans and rot for including as confounds
cc_dem = [cc - repmat(nanmean(cc,2),1,size(cc,2))]';
confound = [cc_dem ones(size(cc_dem,1),1)];

end







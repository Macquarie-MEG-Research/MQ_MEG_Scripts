function plot_sensor_stats(dir_name,stat, alpha, lay, x_lims, save_to_file)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_sensor_stats: a function to plot sensor-level statistics
%
% Author: Robert Seymour (robert.seymour@mq.edu.au)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - dir_name    = directory for saving the results
% - stat       = output from ft_timelockstatistics
% - alpha       = alpha-level
% - lay         = layout generated from ft_preparelayout
% - x_lims      = x-limit of your graph (i.e. which times do you want to
%               plot?)
% save_to_file  = 'yes' will result in .png file being saved to file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ft_warning('This function only supports plotting POSITIVE clusters at present');

cd(dir_name);

% Find the clusters under the specified alpha
pos_cluster_pvals = [stat.posclusters(:).prob];

% If this array is empty, return error
if isempty(pos_cluster_pvals)
    error('NO POSITIVE CLUSTERS BELOW ALPHA LEVEL');
end

% Find the p-values of each cluster
pos_signif_clust = find(pos_cluster_pvals < alpha);

% Give the user some feedback in Command Window
fprintf('Positive Clusters below %.3f alpha level: %d\n',...
    alpha,length(pos_signif_clust));

for t = 1:length(pos_signif_clust)
    fprintf('Positive Cluster #%d: %.3f\n',pos_signif_clust(t),...
        pos_cluster_pvals(pos_signif_clust(t)));
end

%% For each positive cluster...
for t = 1:length(pos_signif_clust)
    
    % Get the significant channels
    pos = ismember(stat.posclusterslabelmat, pos_signif_clust(t));
    highlight_chan = any(pos(:,:)');
    
    % Get the significant times
    index = (any(stat.posclusterslabelmat == pos_signif_clust(t)));
    time_for_topo = stat.time(index');
    
    stat.index = pos;
    
    % Find the time of the peak
    cfg = [];
    cfg.latency = [time_for_topo(1) time_for_topo(end)];
    cfg.channel = stat.label(highlight_chan');
    data_for_peak = ft_selectdata(cfg,stat);
    
    avg_chan  = mean(data_for_peak.stat(:,:));
    time_of_peak = data_for_peak.time(find(max(avg_chan)==avg_chan));
    
    %% Singleplot
    cfg                 = [];
    cfg.channel         = stat.label(highlight_chan');
    cfg.maskparameter   = 'index';
    cfg.xlim            = x_lims;
    cfg.linestyle       = '-k';
    cfg.graphcolor      = 'k';
    cfg.linewidth       = 6;
    %cfg.zlim            = [-4.9 4.9];
    cfg.showlabels      = 'yes';
    cfg.fontsize        = 6;
    cfg.layout          = lay;
    cfg.parameter       = 'stat';
    figure;
    ft_singleplotER(cfg,stat); hold on; 
    scatter(time_of_peak,max(avg_chan),40,'filled','r');

    % Give the title
    title(sprintf('Cluster: #%d\n Time:  %.3fs to %.3fs\nPeak: %.3fs' ...
        ,t,time_for_topo(1),...
        time_for_topo(end),time_of_peak)); 
    
    set(gca,'fontsize', 20);
    set(gca, 'Layer','top');


    xlabel('Time (sec)','FontSize',24);
    ylabel('t-value','FontSize',24);
    
    % Save as png
    if strcmp(save_to_file,'yes')
        disp('Saving figure to .png file');
        print(sprintf('singleplot_pos_cluster_%d',t),'-dpng','-r200');
    else
        disp('Not saving figure to file');
    end
    

    %% Topoplot 
    cfg                  = [];
    cfg.interpolation    = 'v4';
    cfg.marker           = 'off';
    cfg.highlight        = 'on';
    cfg.highlightchannel = stat.label(highlight_chan);
    cfg.highlightsymbol  = '.';
    cfg.highlightsize   = 20;
    cfg.xlim            = [time_for_topo(1) time_for_topo(end)];
    cfg.zlim            = 'maxabs';
    cfg.comment         = 'no';
    cfg.fontsize        = 6;
    cfg.layout          = lay;
    cfg.parameter       = 'stat';
    figure;
    ft_topoplotER(cfg,stat); hold on;
    ft_hastoolbox('brewermap', 1);
    colormap(flipud(brewermap(64,'RdBu'))) % change the colormap
    
    % Give the title
    title(sprintf('Cluster: #%d\n Time: %.3fs to %.3fs\nPeak: %.3fs' ,t,time_for_topo(1),...
        time_for_topo(end),time_of_peak)); 
    
    set(gca,'fontsize', 20);
    
    % Save as png
    if strcmp(save_to_file,'yes')
        disp('Saving figure to .png file');
        print(sprintf('topoplot_pos_cluster_%d',t),'-dpng','-r200');
    else
        disp('Not saving figure to file');
    end
    
end

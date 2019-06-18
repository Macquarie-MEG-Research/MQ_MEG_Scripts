function [sat] = mq_detect_saturations(dir_name,confile,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mq_detect_saturations: a function to calculate where and when saturations
% occur
%
% Author: Robert Seymour June 2019 (robert.seymour@mq.edu.au)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
% - dir_name      = directory containing the subjects preprocessed data
% - confile       = full path to .con file
%
%%%%%%%%%%%%%%%%%%
% Variable Inputs:
%%%%%%%%%%%%%%%%%%
% - min_length    = minumum length of flat data to treat as saturations
%                 (default = 0.01s)
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
% - sat           = structure with labels and times of saturation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(varargin)
    min_length    = 0.01;
else
    min_length    = varargin{1};
end

%% CD to correct directory
disp('Going to the directory specified by dir_name')
cd(dir_name);

%% Epoching & Filtering
disp('Loading data');
% Epoch the whole dataset into one continous dataset and apply
% the appropriate filters
cfg = [];
cfg.headerfile = confile;
cfg.datafile = confile;
cfg.trialdef.triallength = Inf;
cfg.trialdef.ntrials = 1;
cfg = ft_definetrial(cfg);

cfg.continuous = 'yes';
alldata = ft_preprocessing(cfg);

cfg = [];
cfg.channel = alldata.label(1:160);
alldata = ft_selectdata(cfg,alldata);

% Array to hold info about saturated data
sat = [];
count = 1;

disp('Searching the data channel by channel for signal saturation...');
for i = 1:160
    
    % Use regular expressions to get the index and number of
    % repetitions in the signal
    [time_id, number_N] = regexp(regexprep(num2str...
        (~diff(alldata.trial{1,1}(i,:))),' ','')...
        ,'1+','start','match');
    
    % Convert from cell to ?
    number_N = cellfun('length',number_N);
    
    % If any of the repetitions are over min_length
    if any(number_N>min_length*alldata.fsample)
        
        % Add channel to sat label
        fprintf('%s has saturations\n',alldata.label{i,1});
        sat.label{count,1} = alldata.label{i,1};
        
        % Find the indices of the saturations
        number_N_over = find(number_N>min_length*alldata.fsample);
        
        time_data = alldata.time{1,1}(1,:);
        
        % Make .time field in sat
        sat.time{count,1} = [];
        
        % For every saturation
        for r = 1:length(number_N_over)
            
            % Get the index of the saturations
            time_of_sat = time_id(number_N_over(r));
            
            % Get the time (in sec) of the saturation
            time_of_sat_sec = time_data(time_of_sat:time_of_sat+...
                number_N(number_N_over(r)));
            
            % Add this to the .time field
            sat.time{count,1} = [sat.time{count,1}, time_of_sat_sec];
        end
        
        count = count+1;
    end
    
end

if ~isempty(sat)
    
    % Find the overall times when the data is saturated (on any channel)
    all_sat = zeros(length(sat.label),length(alldata.trial{1,1}));
    
    for i = 1:length(sat.label)
        all_sat(i,1:length(sat.time{i,1})) = sat.time{i,1};
    end
    
    unique_all_sat = unique(all_sat);
    unique_all_sat(1) = [];
    
    sat.alltime = unique_all_sat';
    
    clear all_sat;
    
    % Get only data from saturated channels
    cfg = [];
    cfg.channel = sat.label;
    data_saturations = ft_selectdata(cfg,alldata);
    
    % Use ft_layoutplot to see the location of the saturated channels
    cfg = [];
    %cfg.lay =lay;
    cfg.box = 'no';
    %cfg.mask = 'no';
    ft_layoutplot(cfg, data_saturations)
    print('saturated_chans','-dpng','-r200');
    
    % Plot how much of the data is saturated
    
    time_saturated = [];
    
    for r = 1:length(sat.label)
        time_saturated(r) = length(sat.time{r})./alldata.fsample;
    end
    
    % Now add the TOTAL time saturated over any channel
    time_saturated(length(time_saturated)+1) = length(sat.alltime)./...
        alldata.fsample;
    
    figure; stem(time_saturated,'r','LineWidth',2);
    set(gca,'xtick',[1:length(time_saturated)],'xticklabel',...
        vertcat(sat.label, 'TOTAL'))
    ylabel('Time Saturated (s)','FontSize',20);
    ax = gca;
    ax.XAxis.FontSize = 10;
    ax.YAxis.FontSize = 16;
    view(90,90)
    print('time_saturated','-dpng','-r200');
end

end


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
% - min_length          = minumum length of flat data to treat as
%                       saturations (default = 0.01s)
% - MEG_system          = 'child' or 'adult' (default = 'adult')
% - detect_reps_method  = 'string_comp' or 'array'
%
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
% - sat           = structure with labels and times of saturation
%
% EXAMPLE: mq_detect_saturations(dir_name,confile);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(varargin)
    min_length    = 0.01;
    meg_system    = 'adult';
    detect_reps_method = 'array';
    
else
    min_length          = varargin{1};
    meg_system          = varargin{2};
    detect_reps_method  = varargin{3};
end

% Display warning messages for either method
if strcmp(detect_reps_method,'array')
    ft_warning(['The array method is not fully tested yet. Treat '...
        'results with caution']);
    
elseif strcmp(detect_reps_method,'string_comp')
    ft_warning(['The string_comp method runs slowly on MATLAB versions'...
        ' earlier than 2015']);
end

% Try to extract the name of the confile
try
    
    find_last_slash = strfind(confile,'/');
    find_last_slash = find_last_slash(end);
    
    confile_short = confile((find_last_slash+1):(strfind(confile,...
        '.con')-1));
catch
    disp('Cannot extract .con file name.');
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

if strcmp(meg_system,'adult')
    
    cfg = [];
    cfg.channel = alldata.label(1:160);
    alldata = ft_selectdata(cfg,alldata);
    
elseif strcmp(meg_system,'child')
    cfg = [];
    cfg.channel = alldata.label(1:125);
    alldata = ft_selectdata(cfg,alldata);
else
    error('Cannot find the correct system...')
end

% Array to hold info about saturated data
sat = [];
count = 1;

disp('Searching the data channel by channel for signal saturation...');

ft_progress('init', 'text', 'Please wait...')

for i = 1:length(alldata.label)
    % Display the progress of the function
    ft_progress(i/length(alldata.label),...
        'Searching for saturations: %s',alldata.label{i});
    
    if strcmp(detect_reps_method,'array')

        % Use diff & find functions to get the index and number of
        % repetitions in the signal
        X = diff(alldata.trial{1,1}(i,:))~=0;
        B = find([true,X]); % begin of each group
        E = find([X,true]); % end of each group
        D = 1+E-B; % the length of each group
        
        Y = D>1;
        time_id = B(Y);
        yyy = E(Y);
        
        number_N = yyy-time_id;
        
        clear X B E D Y yyy
        
    elseif strcmp(detect_reps_method,'string_comp')
        % Use regular expressions to get the index and number of
        % repetitions in the signal.
        [time_id, number_N] = regexp(regexprep(num2str...
            (~diff(alldata.trial{1,1}(i,:))),' ','')...
            ,'1+','start','match');
        
        % Convert from cell to ?
        number_N = cellfun('length',number_N);
        
    else
        ft_error(['ERROR: The user did specify which method to use for'...
            ' repetition detection detection']);
    end
    
    % If any of the repetitions are over min_length
    if any(number_N>min_length*alldata.fsample)
        
        % Add channel to sat label
        %fprintf('%10s saturations = YES \n',alldata.label{i,1});
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
ft_progress('close');

if ~isempty(sat)
    
    %% Find the overall times when the data is saturated (on any channel)
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
    
    %% Use ft_layoutplot to see the location of the saturated channels
    cfg = [];
    %cfg.lay =lay;
    cfg.box = 'no';
    %cfg.mask = 'no';
    ft_layoutplot(cfg, data_saturations)
    
    % Try to save the figure using the .confile name
    try
        print(['saturated_chans_' confile_short],'-dpng','-r200');
    catch
        print('saturated_chans','-dpng','-r200');
    end
    
    %% Plot how much of the data is saturated
    
    time_saturated = [];
    
    for r = 1:length(sat.label)
        time_saturated(r) = length(sat.time{r})./alldata.fsample;
    end
    
    % Now add the TOTAL time saturated over any channel
    time_saturated(length(time_saturated)+1) = length(sat.alltime)./...
        alldata.fsample;
    
    figure;
    set(gcf,'Position',[100 100 900 800]);
    stem(time_saturated,'r','LineWidth',2);
    set(gca,'xtick',[1:length(time_saturated)],'xticklabel',...
        vertcat(sat.label, 'TOTAL'))
    ylabel('Time Saturated (s)','FontSize',20);
    ax = gca;
    
    if length(sat.label) > 50
        ax.XAxis.FontSize = 7;
    else
        ax.XAxis.FontSize = 10;
    end
    
    ax.YAxis.FontSize = 16;
    view(90,90)
    try
        print(['time_saturated' confile_short],'-dpng','-r200');
    catch
        print('time_saturated','-dpng','-r200');
    end
    
end


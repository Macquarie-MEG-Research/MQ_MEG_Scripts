function [trial_data_no_sats] = mq_remove_sat(trial_data,sat,...
    varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mq_remove_sat: a function to remove trials contaminated by saturations
% Please run mq_detect_saturations before this function
%
% Author: Robert Seymour June 2019 (robert.seymour@mq.edu.au)
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
% - trial_data            = data segmented into trials
% - sat                   = output from mq_detect_saturations
%
%%%%%%%%%%%%%%%%%%
% Variable Inputs:
%%%%%%%%%%%%%%%%%%
% - chans_remove        = List of channels to remove in the form:
%                       {'AGXXX',...}
% - keep_chans          = Do you want to remove the bad channels from
%                       output or keep intact (i.e. for data which has 
%                       been interpolated to remove the sats
%%%%%%%%%%%
% Outputs:
%%%%%%%%%%%
% - trial_data_no_sats  = trial data with the saturated trials removed
%
% EXAMPLE: [data_clean] = mq_remove_sat(alldata2,sat,{'AG155','AG142',...
%            'AG145'},'yes');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(varargin)
    chans_remove = '';
    keep_chans = 'no';
    disp('NOT removing any bad channels with lots of saturation');
else
    chans_remove    = varargin{1};
    keep_chans    = varargin{2};
end

if strcmp(keep_chans,'yes')
    trial_data_spare = trial_data;
end

% If there are channels to remove...
if ~isempty(chans_remove)
    
    % Remove the saturated channels from the sat array
    pos_of_chans = [];
    
    for chan = 1:length(chans_remove)
        IndexC = strfind(sat.label,chans_remove{chan});
        pos_of_chans(chan) = find(not(cellfun('isempty',IndexC)));
    end
    
    sat.label(pos_of_chans) = [];
    sat.time(pos_of_chans) = [];
    
    % If there are still channels to remove...
    if ~isempty(sat.label)
    
    % Now find the overall times when the data is saturated 
    % without the specified channels!
    all_sat = zeros(length(sat.label),trial_data.sampleinfo(end,2));
    
    for i = 1:length(sat.label)
        all_sat(i,1:length(sat.time{i,1})) = sat.time{i,1};
    end
    
    unique_all_sat = unique(all_sat);
    unique_all_sat(1) = [];
    
    sat.alltime = unique_all_sat';
    
    end
    
    % Now remove the channels from the trial_data
    cfg =[];
    
    % Make a cell array with {'meg' + channels to remove}
    chans_list = {'meg'};
    for chan = 1:length(chans_remove)
        ttt = strjoin({'-',chans_remove{chan}},'');
        chans_list{chan+1} = ttt;
    end
    
    fprintf('Removing %d channels from the data\n',length(chans_remove));
    cfg.channel = chans_list;
    trial_data = ft_selectdata(cfg,trial_data);
end

% Check if there are still saturated channels
if isempty(sat.label)
    trial_data_no_sats = trial_data;
    return
end

% Now find which trials overlap with times when the data were saturated
trial_list_with_sats = [];
count = 1;

for trial = 1:length(trial_data.trial)
    data_time = [trial_data.sampleinfo(trial,1) : ...
        trial_data.sampleinfo(trial,2)]./trial_data.fsample;
    
    if ~isempty(find(ismember(data_time,sat.alltime) == 1))
       trial_list_with_sats(count) = trial;
       count = count+1;
    end
end

fprintf('Removing %d of %d trial(s) with saturations\n',...
    length(trial_list_with_sats),length(trial_data.trial));

full_trial_list = [1:1:length(trial_data.trial)];

trials_to_keep = full_trial_list(~ismember(full_trial_list,...
    trial_list_with_sats));

% If the user wants to remove 'bad' channels in the output data
if strcmp(keep_chans,'no')
    cfg = [];
    cfg.trials = trials_to_keep;
    trial_data_no_sats = ft_selectdata(cfg, trial_data);
    
% Else if the user wants to keep 'bad' channels in the output data
elseif strcmp(keep_chans,'yes')
    cfg = [];
    cfg.trials = trials_to_keep;
    trial_data_no_sats = ft_selectdata(cfg, trial_data_spare);
end
    
end
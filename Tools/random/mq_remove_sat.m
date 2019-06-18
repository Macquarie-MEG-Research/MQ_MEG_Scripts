function [grating_no_sats] = mq_remove_sat(grating,sat_alltime)

trial_list_with_sats = [];
count = 1;

for trial = 1:length(grating.trial)
    data_time = [grating.sampleinfo(trial,1) : ...
        grating.sampleinfo(trial,2)]./grating.fsample;
    
    if ~isempty(find(ismember(data_time,sat_alltime) == 1))
       trial_list_with_sats(count) = trial;
       count = count+1;
    end
end

fprintf('Removing %d of %d trial(s) with saturations\n',...
    length(trial_list_with_sats),length(grating.trial));

full_trial_list = [1:1:length(grating.trial)];

trials_to_keep = full_trial_list(~ismember(full_trial_list,...
    trial_list_with_sats));

cfg = [];
cfg.trials = trials_to_keep;
grating_no_sats = ft_selectdata(cfg, grating);
end
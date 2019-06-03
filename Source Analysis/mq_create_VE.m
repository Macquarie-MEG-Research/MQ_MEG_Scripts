function [VE] = mq_create_VE(data_clean,sourceall,labels)
%
% mq_get_VE is a function to combine sensor-level data with filters from
% ft_sourceanalysis to create virtual electrode timeseries for
% specific regions of interest (ROIs)
%
% Author: Robert Seymour (June 2019) robert.seymour@mq.edu.au
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - data_clean  = the clean data used for your source analysis. Should
%               contain all the trials intact (i.e. unaveraged)
% - sourceall   = output of ft_sourceanalysis with filter computed for each
%               ROI
% - labels      = label names for your ROIs
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs (saved to dir_name):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - VE         = Fieldtrip strcuture with virtual electrode (VE)
%               information. Will contain time, label, trial and
%               sampleinfo fields

% EXAMPLE FUNCTION CALL:
% [VE] = mq_get_VE(data_clean,sourceall,labels)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Check whether the inputs to the function are correct

if size(sourceall.avg.filter{1,1},1) > 1
    error('Your filter has more than 1 direction... Use cfg.lcmv.fixedori = yes')
end

if length(labels) ~= size(sourceall.avg.filter,1)
    error('The number of labels does not match the number of filters...');
end


% Specify VE labels,trialinfo for this condition
VE = [];
VE.label = labels;
try
    VE.sampleinfo = data_clean.sampleinfo;
catch
    disp('No sampleinfo field');
end
VE.time  = data_clean.time;


% For every VE...
for i = 1:length(labels)
    fprintf('ROI: %10s done\n',labels{i});
    % Create VE using the corresponding filter
    for trial=1:(length(data_clean.trial))
        % Multiply the filter with the data for each trial
        VE.trial{trial}(i,:) = sourceall.avg.filter{i,1}(:,:)...
            *data_clean.trial{trial}(:,:);
    end
end




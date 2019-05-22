function [source] = get_source_pow(data_clean,sourceall,toi)
%
% get_source_pow is a function to extract power values from the output of
% ft_sourceanalysis between specific times of interest (toi). The function
% will average power.
%
% Author: Robert Seymour (May 2019) robert.seymour@mq.edu.au
%
%%%%%%%%%%%
% Inputs:
%%%%%%%%%%%
%
% - data_clean              = the clean data used for your source analysis
% - sourceall               = output of ft_sourceanalysis for the entire
%                           time-range of interest (ie. baseline and 
%                           trial period)
% - toi                     = times of interest
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs (saved to dir_name):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - source                  = Fieldtrip source structure with modified  
%                           avg.power field reflecting average "power" 
%                           across the toi

% EXAMPLE FUNCTION CALL:
% [sourceN1] = get_source_pow(data_clean,sourceall,[0.1 0.2])



fprintf('Getting source level power from %.3fs to %.3fs\n',toi(1),toi(2)) 

% average across time the dipole moments within the N1 latency range
ind    = find(data_clean.time{1}>=toi(1) & data_clean.time{1}<=toi(2));
tmpmom = sourceall.avg.mom(sourceall.inside);
mom    = sourceall.avg.pow(sourceall.inside);
for ii = 1:length(tmpmom)
    mom(ii) = mean(abs(tmpmom{ii}(ind)));
end

% insert the N1 amplitude in the 'pow' field and save to disk, the
% original pow contains the mean amplitude-squared across the
% time-window used for the channel-level covariance computation
source = sourceall;
source.avg.pow(source.inside) = abs(mom);
source.cfg = rmfield(source.cfg,...
    {'headmodel' 'callinfo'}); % this is removed because it takes up a lot of memory
source = rmfield(source,...
    {'time'}); % this is removed because it takes up a lot of memory

end
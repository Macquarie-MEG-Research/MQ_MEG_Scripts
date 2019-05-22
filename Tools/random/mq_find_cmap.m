% Function to find the specified colormap.mat file and add to workspace

function [ddd] = mq_find_cmap(color_map_name)

try
    ddd = which([color_map_name '.mat']);
    %evalin('base','load(ddd)');
catch
    error('Could not find colormap')
end
end


% Function to find the specified colormap.mat file and add to workspace

function mq_find_cmap(color_map_name)

try
    ttt = which([color_map_name '.mat']);
    load(ttt)
catch
    error('Could not find colormap %s',[color_map_name] '.mat')
end
end


function mq_find_cmap(color_map_name)

try
    ttt = which([color_map_name] '.mat']);
    load(ttt)
catch
    error('Could not find colormap %s 


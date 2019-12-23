## Tools/headshape

- mq_3D_coreg.m 					: function designed for the user to mark the location of
the head-position indicator (or 'marker') coils on a 3D .obj object file,
captured using the Ipad-based Structure Sensor. A downsampled .hsp file
and .elp file are produced.
- headshape_downsample_new.m 		: new function to downsample headshape information for more accurate coregistration. 
- decimate_headshape.m 				: function to decimate headshape information
- downsample_headshape_child.m 		: function to downsample headshape data acquired from children aged 3-7 (hsp file)
- downsample_headshape.m 			: function to downsample headshape data acquired from adolescents & adults **[DECREPIT]**
- add_facial_info.m      			: function to add some average face-points to your headshape data
- *remove_hsp_points.m* 			: function to manually remove headshape points, for instances of errorneous hsp data **[Under Development]**
- *mq_3D_coreg_EEG.m*: 				: function to mark location of marker coils and EEG sensors on a 3D .obj object file,captured using the Ipad-based Structure Sensor **[Under Development]**
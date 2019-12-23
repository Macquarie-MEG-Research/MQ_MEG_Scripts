# Source Level Anaylsis

- find_max_MNI: 	function to find the maximum MNI co-ordinate
- find_min_MNI: 	function to find the minimum MNI co-ordinate
- get_source_pow:	function to extract power values from the output of
					ft_sourceanalysis between specific times of interest (toi). The function
					will average power.
- mq_atlas2VE: 		function to create a virtual electrode using an atlas!
- mq_create_VE: 	function to combine sensor-level data with filters from
					ft_sourceanalysis to create virtual electrode timeseries for
					specific regions of interest (ROIs)

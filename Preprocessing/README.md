# Preprocessing

### Maxwell Filtering

To reduce background environmental noise, you may wish to implement Maxwell filtering. Please see [this MNE-Python tutorial](https://mne.tools/dev/auto_tutorials/preprocessing/plot_60_maxwell_filtering_sss.html?highlight=maxwell_filter) for more information. 

MQ_MEG_Scripts contains a command-line python helper script to implement Maxwell filtering (tSSS) for .con files using MNE-Python:

**[mq_con2fif_maxfilter.py](https://github.com/Macquarie-MEG-Research/MQ_MEG_Scripts/blob/master/Preprocessing/mq_con2fif_maxfilter.py)**

### Detecting Saturations

If there was low-frequency noise present during your recording, certain MEG channels may have flat-lined (or "saturated"). MQ_MEG_Scripts contains the function mq_detect_saturations to detect time-points with saturated MEG data: 
```matlab
[sat] = mq_detect_saturations(dir_name,confile,0.01,'adult','array')
``` 
 
### Loading Data into Fieldtrip

### Filtering

### ICA

### Trial Definition

### Removing "Bad" Trials

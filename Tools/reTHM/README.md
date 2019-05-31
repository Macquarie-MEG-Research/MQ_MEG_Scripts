## Tools/reTHM

Tools for analysing KIT-Macquarie data with real time head tracking (reTHM)

### Functions:

- *get_reTHM_data.m* : function to read reTHM data from .con file, calculate translation/rotation information and produce plots for quality checking your data

- *read_reTHM.m* : sub-function used by get_reTHM_data to extract the data from the .con file

- *circumcenter.m* : calculates circumcentre of 3 fiducial points (i.e. the centre of 3D space)
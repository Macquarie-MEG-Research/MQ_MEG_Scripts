## Read reTHM data into matlab matrix

### File: `read_reTHM.m`

**Language:** `Matlab`


**Function info:**
`read_reTHM(file_path)`:

 - `file_path` is the full path to the `.con` file to be read.


**Returns:**
An (n x 20) matrix of the reTHM data.
Each row is a measurement and contains (x, y, z, gof) for each of the 5 markers.
The first column is the event time in seconds.
---
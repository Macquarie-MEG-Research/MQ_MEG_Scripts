#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Convert KIT data to FIF & perform tSSS
"""

import argparse
parser = argparse.ArgumentParser(description='.con to .fif + Maxwell Filter')
parser.add_argument('-bad','--names-list',nargs="*",
help = """bad channels e.g. 'MEG 144' 'MEG 155'""",action="store",
dest = "bad_chan",required=False)
required = parser.add_argument_group('required arguments')
required.add_argument('-con',help="path to .con file", action="store",
dest = "confile",required=True)
required.add_argument('-elp',help="path to .elp file", action="store",
dest = "elpfile",required=True)
required.add_argument('-mrk',help="path to .mrk file", action="store",
dest = "mrkfile",required=True)
required.add_argument('-hsp',help="path to .hsp file", action="store",
dest = "hspfile",required=True)

args = parser.parse_args()

confile = args.confile
elpfile = args.elpfile
mrkfile = args.mrkfile
hspfile = args.hspfile

# Extract the name of the confile and rename with _raw_tsss.fif
result = confile.split('/')[-1]

print('Converting %s to .fif file and applying maxwell filtering'%(result))

result = result.replace('.con','')
result = result.replace('.','_')
result = result.replace(' ','_')
result = result + '_raw_tsss.fif'

print('Importing MNE')
import mne
from mne.preprocessing import maxwell_filter

print('Loading data...')
# Load Raw
raw = mne.io.read_raw_kit(confile, mrk=mrkfile, elp=elpfile,
hsp=hspfile,verbose=True)

## Check if any bad channels have been specified
if args.bad_chan is not None:
        raw.info['bads'] = args.bad_chan

print('Perorming maxwell_filter (tSSS)')
## Perform tSSS
raw_tsss = maxwell_filter(raw,st_duration=60, st_correlation=0.9)

print('Saving data')
## Save as .fif file
raw_tsss.save(result,buffer_size_sec=1)

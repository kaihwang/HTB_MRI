#!/bin/sh
source /home/despoB/kaihwang/.bashrc;
source activate fmriprep;
#SUB_ID="${SGE_TASK}";
WD='/home/despoB/kaihwang/HTB_fMRI/'
#SCRIPTS='/home/despoB/kaihwang/bin/TTD/Preprocessing'

#cd ${WD}/fmriprep;

fmriprep \
    --participant_label Pilot03 \
    --nthreads 1 \
    --output-space T1w template \
    --template MNI152NLin2009cAsym \
    ${WD}/BIDS/ \
    ${WD}/fmriprep/ \
    participant

#END_TIME=$(date);
#echo "fMRIprep for $SUB_ID completed at $END_TIME";
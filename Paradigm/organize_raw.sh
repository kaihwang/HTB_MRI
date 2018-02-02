

WD='/home/despoB/kaihwang/HTB_fMRI'

for s in Pilot03; do
	
	heudiconv -d ${WD}/Raw/{subject}/*/*/* -s ${s} \
	-f /home/despoB/kaihwang/bin/HTB-MNE/TTD_heuristics.py -c dcm2niix -o ${WD}/BIDS --bids

done
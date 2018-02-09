

WD='/home/despoB/kaihwang/HTB_fMRI'

for s in Pilot04; do
	
	heudiconv -d ${WD}/Raw/{subject}/*/*/* -s ${s} \
	-f /home/despoB/kaihwang/bin/HTB_MRI/TTD_heuristics.py -c dcm2niix -o ${WD}/BIDS --bids

done


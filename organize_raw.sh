

WD='/home/despoB/kaihwang/HTB_fMRI'

for s in Sub41_Htb Sub42_Htb_Notms; do
	
	heudiconv -d ${WD}/Raw/{subject}/*/*/* -s ${s} \
	-f /home/despoB/kaihwang/bin/HTB_MRI/TTD_heuristics.py -c dcm2niix -o ${WD}/BIDS --bids

done


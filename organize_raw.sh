

WD='/home/despoB/kaihwang/HTB_fMRI'

for s in sub43 sub44 sub45 sub46 sub48; do
	
	heudiconv -d /home/despoC/HierarchyThetaBeta/fMRI_Experiment/Session2_Baseline/RawMRI/{subject}/*/*/* -s ${s} \
	-f /home/despoB/kaihwang/bin/HTB_MRI/TTD_heuristics.py -c dcm2niix -o ${WD}/BIDS --bids

done


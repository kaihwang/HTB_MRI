#!/bin/bash
# do group MTD regression analysis


#MTD_Target MTD_Distractor MTD_Target-Baseline MTD_Distractor-Baseline MTD_Target-Distractor BC_Target BC_Distractor BC_Target-Baseline BC_Distractor-Baseline BC_Target-Distractor


data='/home/despoB/kaihwang/HTB_fMRI/Results'
#'sub-7002/ses-Loc'




for contrast in D2-D1_GLT R8-R4_GLT D2+R8-D1-R4_GLT D1+D2-R4+R8_GLT D1_GLT D2_GLT R4_GLT R8_GLT alltask_GLT D1-D2-R4-R8_GLT R4+R8-D1-D2_GLT; do
	# for w in 5 10 15 20; do
	# 	for dset in V1d V1v V2d V2v V3a V3d V3v V4v; do #V1 V1d V1v V2d V2v V3a V3d V3v V4v
	echo "cd /home/despoB/kaihwang/HTB_fMRI/Group 
	3dMEMA -prefix /home/despoB/kaihwang/HTB_fMRI/Group/${contrast}_groupMEMA \\
	-set ${contrast} \\" > /home/despoB/kaihwang/TRSE/TTD/Group/groupstat_${contrast}.sh

	cd ${data}
	
	# MTD_BC_stats_w20_MNI_V2v_REML+orig
	for s in sub-Sub41Htb sub-Sub42HtbNotms sub-sub43 sub-sub45 sub-sub46 sub-sub48 sub-sub49 sub-sub52 sub-sub54 sub-sub53; do 
		cbrik=$(3dinfo -verb ${data}/${s}/FIRmodel_task-HTBMB2_MNI_stats_TR2to7.nii.gz | grep "${contrast}#0_Coef" | grep -o ' #[0-9]\{1,3\}' | grep -o '[0-9]\{1,3\}')
		tbrik=$(3dinfo -verb ${data}/${s}/FIRmodel_task-HTBMB2_MNI_stats_TR2to7.nii.gz | grep "${contrast}#0_Tstat" | grep -o ' #[0-9]\{1,3\}' | grep -o '[0-9]\{1,3\}')

		echo "${s} ${data}/${s}//FIRmodel_task-HTBMB2_MNI_stats_TR2to7.nii.gz[${cbrik}] ${data}/${s}/FIRmodel_task-HTBMB2_MNI_stats_TR2to7.nii.gz[${tbrik}] \\" >> /home/despoB/kaihwang/TRSE/TTD/Group/groupstat_${contrast}.sh
	done

	echo "-cio -mask /home/despoB/kaihwang/HTB_fMRI/Group/mask2.nii.gz" >> /home/despoB/kaihwang/TRSE/TTD/Group/groupstat_${contrast}.sh

	#qsub -l mem_free=3G -V -M kaihwang -m e -e ~/tmp -o ~/tmp /home/despoB/kaihwang/TRSE/TDSigEI/Group/groupstat_${dset}_${contrast}.sh
	. /home/despoB/kaihwang/TRSE/TTD/Group/groupstat_${contrast}.sh

	# 	done
	# done
done

# 			#qsub -l mem_free=3G -V -M kaihwang -m e -e ~/tmp -o ~/tmp /home/despoB/kaihwang/TRSE/TDSigEI/Group/groupstat_${dset}_${contrast}.sh

#!/bin/sh

# test 3dDeconvolve

for s in Pilot03; do

	Raw="/home/despoB/kaihwang/HTB_fMRI/fmriprep/fmriprep/sub-${s}"
	Output='/home/despoB/kaihwang/HTB_fMRI/Results/'

	# for run in 001 002 003 004 005 006 007 008; do

	# 	#low amount of smooth
	# 	3dBlurToFWHM -input ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_preproc.nii.gz \
	# 	-prefix ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_smoothed_preproc.nii.gz \
	# 	-FWHM 6		

	# 	#scaling
	# 	3dTstat -mean -prefix ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_mean.nii.gz \
	# 	${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_smoothed_preproc.nii.gz

	# 	3dcalc \
	# 	-a ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_smoothed_preproc.nii.gz \
	# 	-b ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_mean.nii.gz \
	# 	-c ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_brainmask.nii.gz\
	# 	-expr "(a/b * 100) * c" \
	# 	-prefix ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_smoothed_scaled_preproc.nii.gz

	# 	#remove not needed files
	# 	rm ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_mean.nii.gz
	# 	rm ${Raw}/func/sub-${s}_task-HTBSBTR2_run-${run}_bold_space-T1w_smoothed_preproc.nii.gz
	# done	



	# 
	# mkdir ${Output}/sub-${s}/

	# mri_convert /home/despoB/kaihwang/HTB_fMRI/fmriprep/freesurfer/sub-${s}/mri/T1.mgz ${Output}/sub-${s}/Native_T1.nii.gz
	# fslreorient2std ${Output}/sub-${s}/Native_T1.nii.gz ${Output}/sub-${s}/Native_T1.nii.gz

	# echo "" > ${Output}/sub-${s}/confounds.tsv

	# echo "" > ${Output}/sub-${s}/motion.tsv
	# for f in $(/bin/ls ${Raw}/func/sub-${s}_task-HTBSBTR2_run*confounds.tsv | sort -V); do
	# 	cat ${f} | tail -n+2 | cut -f13-24 >> ${Output}/sub-${s}/confounds.tsv
	# 	cat ${f} | tail -n+2 | cut -f19-24 >> ${Output}/sub-${s}/motion.tsv
	# done

	# 1d_tool.py -infile ${Output}/sub-${s}/motion.tsv \
	# -set_nruns 8 -show_censor_count -censor_motion 0.2 ${Output}/sub-${s}/FD0.2 -censor_prev_TR -overwrite

	# 3dMean -count -prefix ${Output}/sub-${s}/union_mask.nii.gz ${Raw}/func/*task-HTBSBTR2*T1w_brainmask.nii.gz

	3dDeconvolve -input $(/bin/ls ${Raw}/func/sub-${s}_task-HTBSBTR2_run-*_bold_space-T1w_smoothed_scaled_preproc.nii.gz | sort -V) \
	-mask ${Output}/sub-${s}/union_mask.nii.gz \
	-polort A \
	-num_stimts 4 \
	-censor ${Output}/sub-${s}/FD0.2_censor.1D \
	-ortvec ${Output}/sub-${s}/confounds.tsv confounds \
	-stim_times 1 /home/despoB/kaihwang/bin/HTB-MNE/${s}_R4 'TENT(0, 14, 8)' -stim_label 1 R4 \
	-stim_times 2 /home/despoB/kaihwang/bin/HTB-MNE/${s}_R8 'TENT(0, 14, 8)' -stim_label 2 R8 \
	-stim_times 3 /home/despoB/kaihwang/bin/HTB-MNE/${s}_D1 'TENT(0, 14, 8)' -stim_label 3 D1 \
	-stim_times 4 /home/despoB/kaihwang/bin/HTB-MNE/${s}_D2 'TENT(0, 14, 8)' -stim_label 4 D2 \
	-iresp 1 ${Output}/sub-${s}/R4_FIR.nii.gz \
	-iresp 2 ${Output}/sub-${s}/R8_FIR.nii.gz \
	-iresp 3 ${Output}/sub-${s}/D1_FIR.nii.gz \
	-iresp 4 ${Output}/sub-${s}/D2_FIR.nii.gz \
	-gltsym 'SYM: +1*D1[1..4] +1*D2[1..4] -1*R4[1..4] -1*R8[1..4] ' -glt_label 1 D1+D2-R4+R8 \
	-gltsym 'SYM: +1*D2[1..4] +1*R8[1..4] -1*D1[1..4] -1*R4[1..4] ' -glt_label 2 D2+R8-D1-R4 \
	-gltsym 'SYM: +1*R8[1..4] -1*R4[1..4] ' -glt_label 3 R8-R4 \
	-gltsym 'SYM: +1*D2[1..4] -1*D1[1..4] ' -glt_label 4 D2-D1 \
	-gltsym 'SYM: +1*D2[1..4] -1*R8[1..4] ' -glt_label 5 R8-D2 \
	-gltsym 'SYM: +1*D1[1..4] -1*R4[1..4] ' -glt_label 6 D1-R4 \
	-gltsym 'SYM: +1*D2[1..4] -1*R4[1..4] ' -glt_label 7 D2-R4 \
	-gltsym 'SYM: +0.5*R4[1..4] +0.5*R8[1..4] ' -glt_label 8 R4+R8 \
	-gltsym 'SYM: +0.5*D1[1..4] +0.5*D2[1..4] ' -glt_label 9 D1+D2 \
	-rout \
	-tout \
	-bucket ${Output}/sub-${s}/FIRmodel_task-HTBSBTR2_stats.nii.gz \
	-GOFORIT 100 \
	-noFDR \
	-nocout \
	-allzero_OK

done
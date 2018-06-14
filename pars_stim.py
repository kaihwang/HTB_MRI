import scipy.io as sio
import os.path
import numpy as np
import fileinput
import sys


def write_stimtime(filepath, inputvec):
	''' short hand function to write AFNI style stimtime'''
	if os.path.isfile(filepath) is False:
			f = open(filepath, 'w')
			for val in inputvec[0]:
				if val =='*':
					f.write(val + '\n')
				else:
					# this is to dealt with some weird formating issue
					f.write(np.array2string(np.around(val,2)).replace('\n','')[4:-1] + '\n') 
			f.close()



if __name__ == "__main__":

	Subject, num_runs = raw_input().split()
	num_runs=int(num_runs)
	R4_stimtime = [['*']*num_runs]
	R8_stimtime = [['*']*num_runs]
	D1_stimtime = [['*']*num_runs]
	D2_stimtime = [['*']*num_runs]

	for r in np.arange(num_runs):
		
		fn = '/home/despoC/HierarchyThetaBeta/fMRI_Experiment/Session2_Baseline/DesignMatrices/%s/%s_designMatrix_run%s.mat' %(Subject, Subject, r+1)
		m = sio.loadmat(fn)
		
		name = m['names'][0][0][0]
		onsets = m['onsets'][0][0][0]			
		
		if name == 'R4':
			R4_stimtime[0][r] = onsets
		if name == 'D1':
			D1_stimtime[0][r] = onsets
		if name == 'D2':
			D2_stimtime[0][r] = onsets
		if name == 'R8':
			R8_stimtime[0][r] = onsets				

	fn = '/home/despoB/kaihwang/bin/HTB_MRI/DesignMat/%s_D1' %Subject
	write_stimtime(fn, D1_stimtime)	

	fn = '/home/despoB/kaihwang/bin/HTB_MRI/DesignMat/%s_D2' %Subject
	write_stimtime(fn, D2_stimtime)	

	fn = '/home/despoB/kaihwang/bin/HTB_MRI/DesignMat/%s_R4' %Subject
	write_stimtime(fn, R4_stimtime)	

	fn = '/home/despoB/kaihwang/bin/HTB_MRI/DesignMat/%s_R8' %Subject
	write_stimtime(fn, R8_stimtime)		
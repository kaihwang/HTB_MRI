import os

def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    
    allowed template fields - follow python string module: 
    
    item: index within category 
    subject: participant id 
    seqitem: run number during scanning
    subindex: sub index within group
    """
    
    t1w = create_key('anat/sub-{subject}_T1w')
    HTB_MB = create_key('func/sub-{subject}_task-HTBMB_run-{item:03d}_bold')
    HTB_MB_sbref = create_key('func/sub-{subject}_task-HTBMB_run-{item:03d}_sbref')
    HTB_SB = create_key('func/sub-{subject}_task-HTBSB_run-{item:03d}_bold')
    HTB_SBTR2 = create_key('func/sub-{subject}_task-HTBSBTR2_run-{item:03d}_bold')

    #pilot_t1w = create_key('anat/sub-{subject}_T1w')
    #pilot_retinotopy = create_key('func/sub-{subject}_task-Retinotopy_run-{item:03d}_bold')
    #pilot_retinotopy_sbref = create_key('func/sub-{subject}_task-Retinotopy_run-{item:03d}_sbref')

    info = {t1w: [], HTB_MB: [], HTB_MB_sbref: [], HTB_SB: [], HTB_SBTR2: []}

    for idx, seq in enumerate(seqinfo):
        '''
        seq contains the following fields
        * total_files_till_now
        * example_dcm_file
        * series_number
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        '''

        x,y,z,n_vol,protocol,dcm_dir,TE, image_type, series, total = (seq[6], seq[7], seq[8], seq[9], seq[12], seq[3], seq[11], seq[19], seq[18], seq[0] )
        # t1_mprage --> T1w
        #if (protocol == 'MEMPRAGE_P2') and (TE == 1.64):
        #    info[t1w] = [seq[2]]
        
        if (protocol == 't1_mprage') and (TE == 2.98):
            info[t1w] = [seq[2]]

        # epi --> task    
        # if (n_vol == 94) and (z == 40):
        #     info[task].append({'item': seq[2]})

        #if (protocol == 'mb_bold_mb2_2.5mm_retino_100TRs') and (n_vol == 100) and ('NORM' in seq[19]):
        #    info[retinotopy].append({'item': seq[2]})
        
        #if (protocol == 'mb_bold_mb2_2.5mm_retino_100TRs') and (series == 'mb_bold_mb2_2.5mm_retino_100TRs_SBRef') and ('NORM' in seq[19]):  
        #    info[retinotopy_sbref].append({'item': seq[2]})

        if (protocol == 'mb_bold_mb2_2p5mm_AP_ERTTD') and (n_vol == 340) and ('NORM' in seq[19]): #a hack for 7002, where forgot to switch sequence
            info[HTB_MB].append({'item': seq[2]})
        
        if (protocol == 'mb_bold_mb2_2p5mm_AP_ERTTD') and (series == 'mb_bold_mb2_2p5mm_AP_ERTTD_SBRef') and ('NORM' in seq[19]): #a hack for 7002, where forgot to switch sequence
            info[HTB_MB_sbref].append({'item': seq[2]})

        if (protocol == 'tmsMRI_sequence_PA_TR1500_4mm') and (n_vol == 226): #a hack for 7002, where forgot to switch sequence
            info[HTB_SB].append({'item': seq[2]})


        #ep2d_neuro_2tr    
        if (protocol == 'ep2d_neuro_2tr') and (n_vol == 170): #a hack for 7002, where forgot to switch sequence
            info[HTB_SBTR2].append({'item': seq[2]})

        #if (protocol == 'mb_bold_mb2_2p5mm_AP_Retinotopy') and (n_vol == 241) and ('NORM' in seq[19]):
        #    info[pilot_retinotopy].append({'item': seq[2]})
        
        #if (protocol == 'mb_bold_mb2_2p5mm_AP_Retinotopy') and (series == 'mb_bold_mb2_2p5mm_AP_Retinotopy_SBRef') and ('NORM' in seq[19]):
        #    info[pilot_retinotopy_sbref].append({'item': seq[2]})

        #if (protocol == 'mb_bold_mb2_2p5mm_AP_Retinotopy') and (n_vol == 241) and ('NORM' in seq[19]):
        #    info[pilot_retinotopy].append({'item': seq[2]})
        
        #if (protocol == 'mb_bold_mb2_2p5mm_AP_Retinotopy') and (series == 'mb_bold_mb2_2p5mm_AP_Retinotopy_SBRef') and ('NORM' in seq[19]):
        #    info[pilot_retinotopy_sbref].append({'item': seq[2]})
    

    return info

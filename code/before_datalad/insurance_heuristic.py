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

    t1w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_T1w')
    t2w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_T2w')
    pd = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_run-{item:03d}_PD')
    flair_low = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-lowres_run-{item:03d}_FLAIR')
    flair_hi = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-highres_run-{item:03d}_FLAIR')
    info = {t1w: [], t2w: [], pd: [], flair_low: [], flair_hi: []}

    for s in seqinfo:
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
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
        """

        protocol_name = s.protocol_name.upper()
        if 'SAG' in protocol_name and 'T1' in protocol_name and 'MPRAGE' in protocol_name:
            info[t1w].append(s.series_id)
        elif 'SAG T2 SPACE HEAD' in protocol_name:
            info[t2w].append(s.series_id)
        elif 'SAG T2 FLAIR SPACE S' == protocol_name:
            info[flair_hi].append(s.series_id)
        elif 'AX T2 FLAIR' in protocol_name:
            info[flair_low].append(s.series_id)
        elif 'AX PD' in protocol_name:
            info[pd].append(s.series_id)

    return info

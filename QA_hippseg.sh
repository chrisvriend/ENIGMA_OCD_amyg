#!/bin/bash

#####
# change the path to FSL here:

FSLDIR="/opt/fsl-5.0.10"

#####


# usage instructions
Usage() {
    cat <<EOF

    (C) C.Vriend - 1/17/2021
    QA script using a custom python script to check quality of the hippocampal subfield segmentation
    run as ./QA_hippseg.sh file.txt
    file.txt contains a one column list of the subject IDs in the output directory that need to be inspected
    run this script from within the output directory (= SUBJECTS_DIR)
	output is saved to SUBJECTS_DIR/vol+QA

EOF
    exit 1
}

[ _$1 = _ ] && Usage

file=$1

outputdir=$PWD
echo "SUBJECTS_DIR = ${outputdir}"

for subj in `cat ${file}`; do

echo " creating html for hippocampal subfields check of ${subj} "

hippocampus=${outputdir}/${subj}/mri/hippocampus_template.nii.gz
brain=${outputdir}/${subj}/mri/brain.nii.gz
output=${outputdir}/vol+QA/${subj}_hippQC

/neurodocker/segmentQA2html.py --seg ${hippocampus} --brain ${brain} --output ${output}

sleep 1
done

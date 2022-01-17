#!/bin/bash

# this script combines amygdala/hippocampal nuclei/subfields, estimates CSF and WM overlap and creates a picture of slices for QC
# Written By Chris Vriend
# Edited by Anders Lillevik Thorsen and Olga Therese Ousdal, January 2022

# progress bar function
prog() {
    local w=20 p=$1;  shift
    # create a string of spaces, then change them to dots
    printf -v dots "%*s" "$(( $p*$w/46 ))" ""; dots=${dots// /.};
    # print those dots on a fixed-width space plus the percentage etc.
    printf "\r\e[K|%-*s| %3d %s" "$w" "$dots" "$p" "$*";
}

#source directories
export USER="${USER:=`whoami`}"
export FREESURFER_HOME="/opt/freesurfer7"
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh
export FSLDIR="/opt/fsl-5.0.10"
. ${FSLDIR}/etc/fslconf/fsl.sh
export PATH="/opt/fsl-5.0.10/bin:$PATH"
export FSLOUTPUTTYPE=NIFTI_GZ

# input variables
workdir=$1
subj=$2

	# Static paths for testing of script
	#workdir=/data/ENIGMA/amyg_hippo2021/
	#subj=sub-09subject00001


mkdir -p ${workdir}/${subj}/QC

cd ${workdir}/${subj}/mri

# Define version of hippocampus/amygdala segmentation
vers=v21

###############################################################################################
#  Convert brain and segmentations from Freesurfer to niftiformat, then reorient to standard  #
###############################################################################################


# Checks that the segmented hippocampus/amygdala exists, if not then exit script with error
if  [ ! -f lh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.mgz ]; then

		echo "Amygdala/hippocampal segmentation not availabe for ${subj}"
		echo "something may have gone wrong during the FreeeSurfer segmentation"
		echo "inspect:"
		echo "${workdir}/${subj}/mri"
		echo "and try to rerun"
		echo "exiting script"
		exit

# If the segmented hippocampus/amygdala exists then run the program
else

	if [ ! -f brain.nii.gz ]; then
	# Converts skull-stripped brain from mgz to nii
	mri_convert --in_type mgz --out_type nii --out_orientation RAS brain.mgz brain.nii.gz
	fi

	if [ ! -f lh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz ]; then
	# Converts LEFT hemisphere mgz to nii
	mri_convert --in_type mgz --out_type nii --out_orientation RAS \
  lh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.mgz lh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz
	fi

	if [ ! -f rh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz ]; then
	# Converts RIGHT hemisphere mgz to nii
	mri_convert --in_type mgz --out_type nii --out_orientation RAS \
  rh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.mgz rh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz
	fi

	if [ ! -f hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz ]; then
	# Combines LEFT and RIGHT hemisphere into one
	fslmaths lh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz -add \
  rh.hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz
	fi

	if [ ! -f aseg.nii.gz ]; then
	mri_convert --in_type mgz --out_type nii --out_orientation RAS aseg.mgz aseg.nii.gz
	fi

	fslreorient2std hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz
	fslreorient2std aseg.nii.gz aseg.nii.gz
	fslreorient2std brain.nii.gz brain.nii.gz

	##################################################################
	#  Numbers represeting amygdala nuclei and hippocampal subfields  #
	##################################################################

		# hippocampus:
		# 226 HP_tail
		# 231 HP_body
		# 232 HP_head

		# amyg:
		# 7001 Lateral-nucleus
		# 7003 Basal-nucleus
		# 7005 Central-nucleus
		# 7006 Medial-nucleus
		# 7007 Cortical-nucleus
		# 7008 Accessory-Basal-nucleus
		# 7009 Corrrticoamygdaloid-transition
		# 7010 Anterior-amygdalaoid-area-AAA
		# 7015 Paralaminar-nucleus

		# basolateral complexes
		# 7001, 7003, 7008, 7015

		# centromedial complex
		# 7005, 7006

		# cortical like nuclei
		# 7007, 7009

	#######################################################################################################
	#  Create image files for specific subfield/nuclei subdivisions and total amygdala/hippocampus templates #
	#######################################################################################################

	# This loop seperates the different nuclei/subfields into seperate images, which will later be recombined
	i=0
	for r in 226 231 232 7001 7003 7005 7006 7007 7008 7009 7015 ; do # define range of image values which represents different nuclei/subfields

		i=$[$i+1]

		printf " nuclei/subfield:  %1d\r" ${i}

		fslmaths hippoAmygLabels-T1.${vers}.HBT.FSvoxelSpace.nii.gz -thr ${r} -uthr ${r} ${r}_temp.nii.gz

	done

	# Merge basolateral complexes
	fslmaths 7001_temp.nii.gz -add 7003_temp.nii.gz -add 7008_temp.nii.gz -add 7015_temp.nii.gz -bin basolateral_amyg.nii.gz

	# Merge centromedial complex
	fslmaths 7005_temp.nii.gz -add 7006_temp.nii.gz -bin centromedial_amyg.nii.gz

	# Merge basolateral complexes
	fslmaths 7007_temp.nii.gz -add 7009_temp.nii.gz -bin cortical_like_nuclei_amyg.nii.gz

	# create empty image
	fslmaths basolateral_amyg.nii.gz -mul 0 amygdala_template.nii.gz

	# Rename files for hippocampal head, body and tail
	fslmaths 226_temp.nii.gz -bin HP_tail.nii.gz
	fslmaths 231_temp.nii.gz -bin HP_body.nii.gz
	fslmaths 232_temp.nii.gz -bin HP_head.nii.gz

	# Copy empty image so that it can also be used as template for hippocampus
	cp amygdala_template.nii.gz hippocampus_template.nii.gz

	# Combine all amygdala complexes into template
	s=0
	for nuclei in basolateral centromedial cortical_like_nuclei ; do

    s=$[$s+1] # Makes subregions have different values so that they can be visually separated by slicer
		s=$[$s*2] # Multiplies value by 2 (pragmatically chosen after visual quality control) so that the colors from slicer are more seperable
		fslmaths ${nuclei}_amyg.nii.gz -mul ${s} ${nuclei}_amyg.nii.gz

		fslmaths amygdala_template.nii.gz -add ${nuclei}_amyg.nii.gz amygdala_template.nii.gz
		echo "iteration number ${s}"
	done

	# Combine all hippocampus subfields into template
	s=0
	for subfield in tail body head ; do

		s=$[$s+1] # Makes subregions have different values so that they can be visually seperated by slicer
		s=$[$s*2] # Multiplies value by 2 (pragmatically chosen after visual quality control) so that the colors from slicer are more seperable
		fslmaths HP_${subfield}.nii.gz -mul ${s} HP_${subfield}.nii.gz
		fslmaths hippocampus_template.nii.gz -add HP_${subfield}.nii.gz hippocampus_template.nii.gz

	done

	# Remove temporary image files
	rm *_temp.nii.gz

	##############################################
	#  Estimate CSF and WM content per structure #
	##############################################

	for structure in hippocampus amygdala ; do

		# Remove temporary files
		#mv template.nii.gz ${workdir}/${subj}/mri/${structure}_template.nii.gz

		echo " "
		cd ${workdir}/${subj}/QC/

		if [ ! -f brain_pve_0.nii.gz ]; then
		echo "running fast on ${subj}"
		cd ${workdir}/${subj}/mri/
		fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g -o \
		${workdir}/${subj}/QC/brain brain.nii.gz
		fi

		echo "computing CSF mask for ${structure}"
		# multiply CSF segmentation (from fast) with segmentation
		fslmaths ${workdir}/${subj}/mri/${structure}_template.nii.gz \
		-bin -mul ${workdir}/${subj}/QC/brain_seg_0.nii.gz ${workdir}/${subj}/QC/csf_${structure}

		csfoverlap=$(fslstats ${workdir}/${subj}/QC/csf_${structure}.nii.gz -V  | awk '{ print $1 }')

		#if [ -z ${temp} ]; then
		#csfoverlap=0
		#fi

		echo "${subj} ${csfoverlap}" > ${workdir}/${subj}/QC/${subj}_CSF_overlap_${structure}.txt

		echo "computing WM mask for ${structure}"

		# extract L and R WM segmentations from FreeSurfer
		fslmaths ${workdir}/${subj}/mri/aseg.nii.gz -thr 2 -uthr 2 aseg_L
		fslmaths ${workdir}/${subj}/mri/aseg.nii.gz -thr 41 -uthr 41 aseg_R
		fslmaths aseg_L -add aseg_R FS_WM_mask
		rm aseg_L.nii.gz aseg_R.nii.gz

		# multiply WM with segmentation
		fslmaths ${workdir}/${subj}/mri/${structure}_template.nii.gz \
		-bin -mul FS_WM_mask.nii.gz -bin ${workdir}/${subj}/QC/wm_${structure}
		wmoverlap=$(fslstats ${workdir}/${subj}/QC/wm_${structure} -V | awk '{ print $1 }' )
		echo "${subj} ${wmoverlap}" > ${workdir}/${subj}/QC/${subj}_WM_overlap_${structure}.txt


		# create png of slices


		cd ${workdir}/${subj}/mri/

		echo "creating overlay and PNG file of ${structure} slices for QC"
		image_to_slice=${structure}overlay
		overlay 1 0 brain.nii.gz -A ${structure}_template.nii.gz 1 12 ${image_to_slice}

		# find location of Center of Gravity

		locCfloat=$(fslstats ${structure}_template.nii.gz  -C | awk '{ print $3}')
		locC=${locCfloat%.*}
		minslice=$(echo "${locC} - 10 " | bc -l)
		maxslice=$(echo "${locC} + 13 " | bc -l)

		number_of_slices=$(echo "${maxslice} - ${minslice}" | bc -l)
		number_of_slices_brain=$(fslval ${image_to_slice} dim3)
		#Calculate the max spacing necessary to allow 24 slices to be cut
		let slice_increment=(${number_of_slices}+24-1)/24


		#####################################################################

		## Run loop to slice and stitch slices

		#####################################################################

		count=1
		col_count=7
		row=0

		#Slice the image.
		echo "processing..."
		for (( N = ${minslice}; N <= ${maxslice}; N += ${slice_increment} )); do
		  printf "slice: %1d\r" ${N}
		  FRAC=$(echo "scale=2; ${N} / ${number_of_slices_brain}" | bc -l);
		  slicer ${image_to_slice} -L -z ${FRAC} ${image_to_slice}_${count}.png;

		  #Add current image to a row.
		  #If you have the first image of a new row (i.e., column 7), create new row
		  if [[ $col_count == 7 ]] ; then
		    row=$(echo "${row} + 1" | bc -l);
		    mv ${image_to_slice}_${count}.png ${structure}_slices_row${row}.png
		    col_count=2;
		    just_started_a_new_row=1;
		  #Otherwise, append your image to the existing row.
		  else
		    pngappend ${structure}_slices_row${row}.png + ${image_to_slice}_${count}.png ${structure}_slices_row${row}.png
		    col_count=$(echo " ${col_count} + 1 " | bc -l);
		    just_started_a_new_row=0;
		    rm ${image_to_slice}_${count}.png
		  fi
		  count=$(echo  "${count} +1 " | bc -l);
		done

		#####################################################################

		## Stitch your rows into a single slices

		#####################################################################

		label=${subj}

		mv ${structure}_slices_row1.png ${structure}_slices-${label}.png
		pngappend ${structure}_slices-$label.png - ${structure}_slices_row2.png ${structure}_slices-$label.png
		pngappend ${structure}_slices-$label.png - ${structure}_slices_row3.png ${structure}_slices-$label.png
		pngappend ${structure}_slices-$label.png - ${structure}_slices_row4.png ${structure}_slices-$label.png
		#pngappend ${structure}_slices-$label.png - ${structure}_slices_row5.png ${structure}_slices-$label.png
		#pngappend ${structure}_slices-$label.png - ${structure}_slices_row6.png ${structure}_slices-$label.png

		rm ${structure}_slices_row*
		mv ${workdir}/${subj}/mri/${structure}_slices-${label}.png ${workdir}/${subj}/QC/${structure}_slices-${label}.png

	done
	echo "done with ${subj}"
fi

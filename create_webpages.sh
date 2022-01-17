#!/bin/bash

SUBJECTS_DIR=$1
cd ${SUBJECTS_DIR}

QCdir=${SUBJECTS_DIR}/vol+QA

mkdir -p ${QCdir}

# find subject directories
ls -d sub-*/ > temp.txt
subjects=$(sed 's:/.*::' temp.txt)
rm temp.txt

#################
## HIPPOCAMPUS ##
#################

echo "<html>" 												>  ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "<head>"                                   >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "<style type=\"text/css\">"						>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "*"                                        >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "{"														>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "margin: 0px;"										>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "padding: 0px;"										>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "}"														>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "html, body"											>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "{"														>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "height: 100%;"										>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "}"														>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "</style>"											>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "</head>"												>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "<body>" 												>> ${QCdir}/ENIGMA_hipp_subseg_QC.html



for subj in ${subjects};
do

echo -n "${subj} "

file=${SUBJECTS_DIR}/${subj}/QC/hippocampus_slices-${subj}.png

	echo "<table cellspacing=\"1\" style=\"width:100%;background-color:#000;\">"								>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "<tr>"																																									>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "<td> <FONT COLOR=WHITE FACE=\"Geneva, Arial\" SIZE=6> ${subj} </FONT> </td>"             >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "</tr>"                                                                                >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "<tr>"                                                                                 >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "<td><a href=\"file:${file}\"><img src=\"${file}\" width=\"100%\" ></a></td>"	>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "</tr>"																				>> ${QCdir}/ENIGMA_hipp_subseg_QC.html
	echo "</table>"                                                         >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
done;
echo "</body>"                                                             >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo "</html>"                                                             >> ${QCdir}/ENIGMA_hipp_subseg_QC.html
echo
echo "saved webpage to:"
echo "${QCdir}/ENIGMA_hipp_subseg_QC.html"


#################
## AMYGDALA ##
#################


echo "<html>" 												>  ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "<head>"                                   >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "<style type=\"text/css\">"						>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "*"                                        >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "{"														>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "margin: 0px;"										>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "padding: 0px;"										>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "}"														>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "html, body"											>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "{"														>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "height: 100%;"										>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "}"														>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "</style>"											>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "</head>"												>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "<body>" 												>> ${QCdir}/ENIGMA_amyg_subseg_QC.html



for subj in ${subjects};
do

echo -n "${subj} "

file=${SUBJECTS_DIR}/${subj}/QC/amygdala_slices-${subj}.png

	echo "<table cellspacing=\"1\" style=\"width:100%;background-color:#000;\">"								>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "<tr>"																																									>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "<td> <FONT COLOR=WHITE FACE=\"Geneva, Arial\" SIZE=6> ${subj} </FONT> </td>"             >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "</tr>"                                                                                >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "<tr>"                                                                                 >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "<td><a href=\"file:${file}\"><img src=\"${file}\" width=\"100%\" ></a></td>"	>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "</tr>"																				>> ${QCdir}/ENIGMA_amyg_subseg_QC.html
	echo "</table>"                                                         >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
done;

echo "</body>"                                                             >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo "</html>"                                                             >> ${QCdir}/ENIGMA_amyg_subseg_QC.html
echo
echo "saved webpage to:"
echo "${QCdir}/ENIGMA_amyg_subseg_QC.html"

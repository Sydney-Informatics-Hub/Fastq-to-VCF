#!/bin/bash

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: bash Scripts/align_make_input.sh <cohort.config>
# Version: 
#
# For more details see: https://github.com/Sydney-Informatics-Hub/Fastq-to-VCF
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub.
#
# Suggested acknowledgement:
# The authors acknowledge the support provided by the Sydney Informatics Hub,
# a Core Research Facility of the University of Sydney. This research
# was undertaken with the assistance of resources and services from the National
# Computational Infrastructure (NCI), which is supported by the Australian
# Government, and the Australian BioCommons which is enabled by NCRIS via
# Bioplatforms Australia funding.
#
##########################################################################


if [ -z $1 ]
then
	printf "Please provide <cohort>.config as command-line argument to this script.\nExiting\n"
	exit
else
        config=$1
fi
	
inputs=./Inputs/align_UNSPLIT.inputs
rm -f $inputs

ref=./Reference/GCF_009914755.1_T2T-CHM13v2.0_genomic.fasta
fastq_dir=./Fastq


awk 'NR>1' ${config} | while read LINE
do 
	sample=`echo $LINE | cut -d ' ' -f 1`
	labSampleID=`echo $LINE | cut -d ' ' -f 2`
	centre=`echo $LINE | cut -d ' ' -f 3`
	platform=`echo $LINE | cut -d ' ' -f 4`
	lib=`echo $LINE | cut -d ' ' -f 5`
	
	if [ ! "$lib" ]
	then
	    	lib=1
	fi
		
	fqpairs=($(ls ${fastq_dir}/*${sample}*.f*.gz | sed 's/_R1.*\|_R2.*\|_R1_*\|_R2_*\|.R1.*\|.R2.*//'  | uniq))
	
	#Get the flowcell and lane info from the original pairs:	
	for fqpair in ${fqpairs[@]}
	do
		echo $fqpair
		flowcell=$(zcat ${fqpair}*R1*.fastq.gz | head -1 | cut -d ':' -f 3)
		lane=$(zcat ${fqpair}*R1*.fastq.gz | head -1 | cut -d ':' -f 4)	


		fq1=$(ls ${fqpair}*R1*.f*q.gz)
		fq2=$(ls ${fqpair}*R2*.f*q.gz)
		prefix=$(basename $fqpair)
		printf "${prefix},${fq1},${fq2},${labSampleID},${centre},${lib},${platform},${flowcell},${lane},${ref}\n" >> $inputs
	
			
	done			
done	

printf "`wc -l < ${inputs}` alignment task input lines writen to ${inputs}\n"

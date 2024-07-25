#! /bin/bash

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: 
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

inputs=./Inputs/final_bam.inputs
rm -f $inputs

indir=./Align_split
outdir=./Final_bam
split_disc=./Split_disc
logdir=./Logs/Final_bam

mkdir -p $outdir $split_disc $logdir

awk 'NR>1' ${config} | while read LINE
do 
        sample=`echo $LINE | cut -d ' ' -f 1`
        labSampleID=`echo $LINE | cut -d ' ' -f 2`
	
	printf "${sample},${labSampleID},${indir},${outdir},${split_disc},${logdir}\n" >> $inputs
	
done

printf "`wc -l < ${inputs}` task input lines writen to ${inputs}\n"

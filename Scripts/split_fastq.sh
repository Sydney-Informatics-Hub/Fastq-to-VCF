#!/bin/bash 

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: Do not execute this script directly
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

prefix=`echo $1 | cut -d ',' -f 1`
fq1=`echo $1 | cut -d ',' -f 2`
fq2=`echo $1 | cut -d ',' -f 3`
outdir=`echo $1 | cut -d ',' -f 4`
log=`echo $1 | cut -d ',' -f 5`
split=`echo $1 | cut -d ',' -f 6`


fastp -i ${fq1} \
	-I ${fq2} \
	-AGQL \
	-w ${NCPUS} \
	-S ${split} \
	-d 0 \
	--out1 ${outdir}/${prefix}_R1.fastq.gz \
	--out2 ${outdir}/${prefix}_R2.fastq.gz 2> ${log}
	

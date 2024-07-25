#!/bin/bash

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: Do not execute this scrip directly
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

fastq=`echo $1 | cut -d ',' -f 1`
outdir=`echo $1 | cut -d ',' -f 2`
log=`echo $1 | cut -d ',' -f 3`


fastqc --extract -o ${outdir} ${fastq} >> ${log} 2>&1


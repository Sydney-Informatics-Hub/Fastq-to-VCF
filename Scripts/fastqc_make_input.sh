#! /bin/bash

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: bash Scripts/fastqc_make_input.sh
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


fastq=./Fastq

outdir=./FastQC
logdir=./Logs/FastQC
mkdir -p ${outdir} ${logdir} 

inputs=./Inputs/fastqc.inputs
rm -rf ${inputs}

fastq=$(ls ./Fastq/*.f*q.gz)
fastq=($fastq)


for fastq in ${fastq[@]}
do
	prefix=$(basename $fastq | sed 's/.f\w*q.gz$//')
	log=${logdir}/${prefix}.log
	printf "${fastq},${outdir},${log}\n" >> ${inputs}
done

printf "`wc -l < ${inputs}` fastQC task input lines writen to ${inputs}\n"

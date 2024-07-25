#!/bin/bash

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

inputs=./Inputs/split_fastq.inputs
rm -rf $inputs

split=2000000 # number of fastq lines per output file (divide by 4 gives number of reads)

outdir=./Fastq_split
logdir=./Logs/Fastq_split
fastq_dir=./Fastq

mkdir -p $outdir $logdir

pairs=($(ls ${fastq_dir}/*.f*q.gz | sed 's/_R1.*\|_R2.*\|_R1_*\|_R2_*\|.R1.*\|.R2.*//' | uniq))

for pair in ${pairs[@]}
do
	prefix=$(basename $pair)	
	log=${logdir}/${prefix}.log
	fq1=$(ls ${pair}*R1*.f*q.gz)
	fq2=$(ls ${pair}*R2*.f*q.gz)

	printf "${prefix},${fq1},${fq2},${outdir},${log},${split}\n" >> ${inputs}
done

printf "`wc -l < ${inputs}` split fastq pairs written to ${inputs}\n"

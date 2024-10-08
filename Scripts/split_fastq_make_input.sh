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

split=40000000 # number of fastq lines per output file (divide by 4 gives number of reads)

outdir=./Fastq_split
logdir=./Logs/Fastq_split
fastq_dir=./Fastq

printf "All fastq files in ${fastq_dir} are about to be split and written to ${outdir}\n"
printf "If you have previously split these fastq to this output directory, you MUST first\n"
printf "run a cleanup. Fastp does not produce consistent numeric output names and re-splitting\n"
printf "to the same directory may cause an unintended duplication of some reads.\n"
printf "\nWould you like to continue? Please enter 'N' if you need to cancel and cleanup manually,\n"
printf "'C' to run cleanup now (will delete all contents of ${outdir}), or 'Y' to continue without cleanup:\n"
read response



if [[ $response == Y ]]
then 
	printf "\nContinuing without cleanup\n\n"
elif [[ $response == N ]]
then 
	printf "\nExiting. Please perform manual cleanup then resubmit.\n"
	exit
elif [[ $response == C ]]
then 
	printf "\nCleaning up ${outdir} then continuing.\n"
	# Cleanup using a safer way
	thisdir=${PWD}
	cd ${outdir}
	rm -rf *
	cd ${thisdir} 
else 
	printf "\nYour response $response does not match accepted - please use Y, N or C.\n"
	exit
fi

mkdir -p $outdir $logdir

#pairs=($(ls ${fastq_dir}/*.f*q.gz | sed 's/_R1\.*\|_R2\.*\|_R1_*\|_R2_*\|\.R1\.*\|\.R2\.*//' | uniq))
pairs=($(ls ${fastq_dir}/*.f*q.gz | sed 's/_R1\..*\|_R2\..*\|_R1_.*\|_R2_.*\|\.R1.\.*\|\.R2.\.*//' | uniq))

for pair in ${pairs[@]}
do
	prefix=$(basename $pair)	
	log=${logdir}/${prefix}.log
	fq1=$(ls ${pair}*R1*.f*q.gz)
	fq2=$(ls ${pair}*R2*.f*q.gz)

	printf "${prefix},${fq1},${fq2},${outdir},${log},${split}\n" >> ${inputs}
done

printf "`wc -l < ${inputs}` split fastq pairs written to ${inputs}\n"

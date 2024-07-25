#!/bin/bash

##########################################################################
#
# Platform: NCI Gadi HPC
# Usage: bash Scripts/deepvariant_run_loop.sh <config>
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

ref=./Reference/GCF_009914755.1_T2T-CHM13v2.0_genomic.fasta

script=./Scripts/deepvariant.pbs

pbs_logdir=./PBS_logs/DeepVariant
logdir=./Logs/DeepVariant
outdir=./gVCF
bamdir=./Final_bam

mkdir -p ${pbs_logdir} ${logdir} ${outdir}


awk 'NR>1' ${config} | while read LINE
do 
	sample=`echo $LINE | cut -d ' ' -f 1`
	labSampleID=`echo $LINE | cut -d ' ' -f 2`
	centre=`echo $LINE | cut -d ' ' -f 3`
	lib=`echo $LINE | cut -d ' ' -f 4`
	platform=illumina
	
	if [ ! "$lib" ]
	then
	    	lib=1
	fi

	echo Submitting $labSampleID
	
	bam=${bamdir}/${labSampleID}.final.bam
	vcf=${outdir}/${labSampleID}.g.vcf.gz
	log=${logdir}/${labSampleID}.log
	
	job_name=DV-${labSampleID}
	o_log=${pbs_logdir}/${labSampleID}.o
	e_log=${pbs_logdir}/${labSampleID}.e
	
	qsub -N ${job_name} -o ${o_log} -e ${e_log}  -v ref="${ref}",bam="${bam}",vcf="${vcf}",log="${log}" ${script}
	
	sleep 2
done

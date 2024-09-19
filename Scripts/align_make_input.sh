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

# Just in case... 
dos2unix $config

platform='ILLUMINA'
 
inputs=./Inputs/align.inputs
rm -f $inputs

ref=./Reference/GCF_009914755.1_T2T-CHM13v2.0_genomic.fasta
fastq_dir=./Fastq
fastq_split_dir=./Fastq_split

outdir=./Align_split
errdir=./Logs/Align_split_error_capture
logdir=./Logs/BWA

mkdir -p ${outdir} ${errdir} ${logdir}

awk 'NR>1' ${config} | while read LINE
do 
	sample=`echo $LINE | cut -d ' ' -f 1`
	labSampleID=`echo $LINE | cut -d ' ' -f 2`
	centre=`echo $LINE | cut -d ' ' -f 3`
	lib=`echo $LINE | cut -d ' ' -f 4`
	
	if [ ! "$lib" ]
	then
	    	lib=1
	fi

	fqpairs=($(ls ${fastq_dir}/*${sample}*.f*.gz | sed 's/_R1\..*\|_R2\..*\|_R1_.*\|_R2_.*\|\.R1.\.*\|\.R2.\.*//' | uniq))
		
	#Get the flowcell and lane info from the original pairs:	
	for fqpair in ${fqpairs[@]}
	do	
		#### CHECK THAT ALL YOUR FASTQ MATCHES THIS READ ID FORMAT ###		
		flowcell=$(zcat ${fqpair}*R1*.f*q.gz | head -1 | cut -d ':' -f 3)
		lane=$(zcat ${fqpair}*R1*.f*q.gz | head -1 | cut -d ':' -f 4)	
		
		# Allow for SRA reads: 
		if [[ $flowcell == @SRR* ]]
		then
			flowcell=unknown
			lane=unknown
		fi

		#Print each of the split chunks with flowcell and lane info to inputs file:
		set=$(basename ${fqpair})

		splitpairs=($(ls ${fastq_split_dir}/*${set}*R1*.f*q.gz | sed -E 's/R1\.(fastq|fq)\.gz$//'))

		for pair in ${splitpairs[@]}
		do
			fq1=$(ls ${pair}*R1*.f*q.gz)
			fq2=$(ls ${pair}*R2*.f*q.gz)
			prefix=$(basename $pair | sed 's/\_$//')
			out=${outdir}/${prefix}.nameSorted.bam 
			err=${errdir}/${prefix}.err
			log=${logdir}/${prefix}.log
			rm -rf $out $err $log
   			bytes=$(ls -lL ${fq1} | awk '{print $5}')
			
			printf "${fq1},${fq2},${labSampleID},${centre},${lib},${platform},${flowcell},${lane},${ref},${out},${err},${log},${bytes}\n" >> $inputs	
		done			
	done			
done	

# Reverse numeric sort on byte size
sort -rnk 13 -t ',' ${inputs} > ${inputs}-sorted
mv ${inputs}-sorted ${inputs}

printf "`wc -l < ${inputs}` alignment task input lines writen to ${inputs}\n"

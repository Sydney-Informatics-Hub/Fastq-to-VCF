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
sample=`echo $1 | cut -d ',' -f 4`
seq_centre=`echo $1 | cut -d ',' -f 5`
library=`echo $1 | cut -d ',' -f 6`
platform=`echo $1 | cut -d ',' -f 7`
flowcell=`echo $1 | cut -d ',' -f 8`
lane=`echo $1 | cut -d ',' -f 9`
ref=`echo $1 | cut -d ',' -f 10`


##### 
#Align

out=${outdir}/${prefix}.nameSorted.bam 
err=${errdir}/${prefix}.err
log=${logdir}/${prefix}.log

rm -rf $out $err $log

#bwa-mem2 mem \
./bwa-mem2-2.2.1_x64-linux/bwa-mem2 mem \
	-M \
	-t $NCPUS \
	-K 10000000\
	$ref \
	-R "@RG\tID:${flowcell}.${lane}_${sample}_${library}\tPL:${platform}\tPU:${flowcell}.${lane}\tSM:${sample}\tLB:${sample}_${library}\tCN:${seq_centre}" \
	$fq1 \
	$fq2 \
	2> ${log} \
	| samtools sort -@ ${NCPUS} -m 2G -o ${out}  -

#####
# Multiple checks on the output:

if ! samtools quickcheck ${out}
then 
        printf "Corrupted or missing BAM\n" > ${err}  
fi

if [ ! -e $out ]
then
    echo "$out is missing" >> ${err}
elif [ ! -s $out ]
then
    echo "$out is zero bytes" >> ${err}
fi

if ! grep -q "Computation ends" ${log}
then 
	printf "Error in BWA log\n" >> ${err}
fi

#####

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


sample=`echo $1 | cut -d ',' -f 1`
labSampleID=`echo $1 | cut -d ',' -f 2`
indir=`echo $1 | cut -d ',' -f 3`
outdir=`echo $1 | cut -d ',' -f 4`
split_disc=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`

bams=$(find ${indir} -name "*${sample}*bam"| xargs echo)

\rm -rf ${outdir}/${labSampleID}.merged.bam
lfs setstripe -c 15 ${outdir}/${labSampleID}.merged.bam

# Outfiles:
merged_bam=${outdir}/${labSampleID}.merged.bam
disc_out=${split_disc}/${labSampleID}.disc.sam
split_out=${split_disc}/${labSampleID}.split.sam
final_bam=${outdir}/${labSampleID}.final.bam
log=${logdir}/${labSampleID}.log

# Merge the split BAMs:
sambamba merge -t $NCPUS ${merged_bam} $bams

# Dedup, sort and index  (CSI is the default unless specified):
samtools view -@ 2 -h ${merged_bam} \
       | samblaster -M -e -d ${disc_out} -s ${split_out} 2>${log} \
       | samtools sort -@ ${NCPUS} --write-index -m 2G -o ${final_bam}##idx##${final_bam}.bai - 

# Fastq-to-VCF
High throughput illumina mammalian whole genome sequence analysis and joint genotyping using BWA-mem2 aligner, DeepVariant variant caller and GLnexus joint genotyper.

This workflow was written for NCI Gadi HPC and uses the `nci-parallel` custom utility to parallelise tasks across the cluster with PBS Pro and Open-MPI. Adaptation to other infrastructures will need to adjust this parallelisation method. 

# Usage notes

Clone the repository and change into it
```
git clone git@github.com:Sydney-Informatics-Hub/Fastq-to-VCF.git
cd Fastq-to-VCF
```

The scripts are all within `Scripts` directory, and contain relative paths to the base working directory, so all scripts are to be executed from within the base `Fastq-to-VCF` working directory. It is not recommended to change directory paths within the scripts; if this is done, downstream scripts will also need to be modified. 

All required directories are made by the scripts. Edits need only be made to the PBS directives (NCI project code, lstorage paths, and resource requests). Any other edits (such as specifying the reference sequence and cohort name) are described at the steps below. No other changes to the workflow scripts are required. 

All software used in this workflow are globally installed on Gadi, except GLnexus which is a singularity image file (dowlonad instructions provided at the steps below).

# Input files

1. Copy or symlink your paired gzipped fastq files to `./Fastq`
2. Copy or symlink your reference fasta to `./Reference`
3. Create your sample configuration file, which has one row per sample

## Example configuration file


# Run the workflow

## 1. FastQC

## 2. FastQC multiQC

## 3. Split fastq

## 4. Split fastq check 

## 5. Align split fastq

## 6. Create final BAMs (merge, mark duplicates, sort, index)

## 7. BAM QC

## 8. BAM QC multiQC

## 9. Create per sample gVCF

## 10. Joint genotype 
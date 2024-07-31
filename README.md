# Fastq-to-VCF
High throughput illumina mammalian whole genome sequence analysis and joint genotyping using BWA-mem2 aligner, DeepVariant variant caller and GLnexus joint genotyper.

This workflow was written for NCI Gadi HPC and uses the `nci-parallel` custom utility to parallelise tasks across the cluster with PBS Pro and Open-MPI. Adaptation to other infrastructures will need to adjust this parallelisation method. 

# Usage overview

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

Explanation of columns
1. **SampleID:** The unique identifier that can be used to associate all fastq files that belong to the sample. Must be unique in the cohort and present as prefix for all fastq files belonging to the sample
2. **LabSampleID:** The sample ID that you want to use in your final output files eg BAM, VCF. Can be the same as column 1 or different. Must be unique in the cohort 
3. **Seq_centre:** The sequencing centre that produced the fastq (no whitespace)
4. **Lib:** Library ID. Can be left blank if not relevant; will default to '1'

| #SampleID | LabSampleID  | Seq_centre | Lib |
|-----------|--------------|------------|-----|
| NA12890   | NA12890_mini | Unknown    | 1   |
| NA12878   | NA12878_mini | Unknown    | 1   |


# Parallelisation
Some steps are parallel by sample, and other steps are parallel by fastq. Alignment is executed after first splitting the fastq up into smaller pairs, to enable a much higher degree of parallelisation than simply aligning the fastq pairs as-is.  Only the MultiQC and final joint genotyping steps are executed as single (not parallel) jobs. 

For the parallel jobs, there are 3 workflow scripts per step:

1. `<stepname>_make_input.sh`: This script is executed on the login node with `bash`, and creates the input file required to parallelise the tasks. Each line in the output file `Inputs/<stepname>.inputs` contains the details for one parallel task such as sample ID, fastq, reference, etc. The PBS script (2) will launch the task script (3) once for every line in this 'inputs' file. Any changes regarding the inputs (such as reference sequence name) should be made in this script; no parameter changes should be required in the PBS (2) or task(3) script. 
2. `<stepname>_run_parallel.sh`: This script is submitted with `qsub` and runs the parallel job. Users will need to edit the NCI project code, `lstorage` directory, and resource requests. Note that the requests for the job are for the *whole* job, not for each single task. The variable `NCPUS` within the script body sets the number of CPUs that are allocated to each single task. Tasks may be executed all at once (eg 4 NCPUs per task, 24 tasks, running on 4 x 24 = 96 CPUs). If the total number of CPUs requested for the job is less than the number required to run all at tasks at once, the job wil simply assign tasks to CPUs in the order in which they appear in the inputs list, until all taks are run, or walltime is exceeded. For jobs where all tasks are expected to have similar walltime, requesting the number of total CPUs such that all tasks can be run at once (up to the Gadi queue limits) is reasonable. For jobs where unequal walltimes are expected, for example in cancer studies where tumour has greater coverage than normal samples, size-sorting the inputs largest to smallest or separating the job into separate batches with different inputs lists and walltimes will provide better CPU and KSU efficiency.
3. `<stepname>.sh`: This is the task script that contains the commands required to run the job. It is launched once per task by the PBS script (2) and is not submitted directly by the user. There should not be need to edit this script unless changes to the actual analysis task are warranted. 

# Logs

Tool logs are created into the `Logs` directory, for example the align step will create per-task logs into `Logs/BWA`. 

PBS logs are written to `PBS_logs`. 


# Run the workflow

## 0. Index the reference genome

The reference fasta to index should be within (or symlinked to) the `./Reference` directory. 

This step need only be done once per reference. If previously generated indexes (with the same tool versions) are available, copy or symlink them to the `./Reference` directory along with the fasta. They must all have the same filename prefix. 

Edit the script `Scripts/index_reference.pbs`:

- `-P <NCI poject code>`
- `-lstorage` - specify all required NCI storage paths eg `-l storage=<scratch/a00+gdata/xy11+massdata/a00>`
- update `ref` variable to your reference sequence

The human T2T genome completed in 42 minutes and 85 GB RAM. 

Submit:
```
qsub Scripts/index_reference.pbs
```

Sucessful indexing should create 6 index files within the `./Reference` directory. Check the PBS logs `PBS_logs/index_reference.e` and `PBS_logs/index_reference.o` for errors. 

## 1. FastQC

This script will run FastQC over every single fastq file, using 1 thread per fastq file. 

Ensure you have copied or symlinked your paired gzipped fastq files to `./Fastq`.

### Make parallel inputs file
```
bash Scripts/fastqc_make_input.sh
```

### Edit the PBS script 

Edit `Scripts/fastqc_run_parallel.pbs`: 

- `PBS -P <NCI poject code>`
- `PBS -lstorage` - specify all required NCI storage paths eg `-l storage=<scratch/a00+gdata/xy11+massdata/a00>`
- `PBS -l ncpus=` - adjust this based on your number of fastq files (number of line sin your input file). Eg 500 fastq files = 500 ncpus = 10.4 Gadi normal nodes = round up to 11 nodes = request 528 ncpus to run all fastq files in parallel. If requesting fewer ncpus than required to run all fastq in parallel, ensure to increase walltime to allow for this. 
- `PBS -l mem=` - for ncpus < 48, set to 4 x the number of ncpus. For whole nodes, request number of nodes X 190 GB mem. 
- `PBS -l walltime=` - adjust based on your sample coverage and whether all fastqc tassk will run at the same time or not. 

### Submit
```
qsub Scripts/fastqc_run_parallel.pbs
```

### Check 
- FastQC output in `./FastQC`: html, zip and unzipped folder for each input fastq 
- Exit status 0 and appropriate walltime in `PBS_logs/fastqc.o`
- All tasks have "exited with status 0" in `PBS_logs/fastqc.e`:

```
grep "exited with status 0" PBS_logs/fastqc.e | wc -l
```

- The number should match the number of fastq in your input list. If not, use grep to obtain the failed tasks, make a separate input list, and resubmit those tasks, correcting any errors or revising the walltime as required. 

## 2. FastQC multiQC

This script can be run on the login node for small numbers of fastqc reports, or submitted to the 
compute queue for larger cohorts. 

### To run on login node for small cohorts
```
bash Scripts/multiqc_fastqc.pbs
```

### To run on compute queue for larger cohorts

Edit the script `Scripts/multiqc_fastqc.pbs`

- `PBS -P <NCI poject code>`
- `PBS -lstorage` - specify all required NCI storage paths 
- `PBS -l walltime=` increase as required

Submit:
```
 qsub `Scripts/multiqc_fastqc.pbs`
```

Output report will be in `./MultiQC/FastQC`. 

## 3. Split fastq

Paired FASTQ files are split into smaller files with fastp v.0.20.0 [(Chen et al. 2018)](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234) to enable higher levels of parallelisation. 

The number of *lines* per output fastq file is governed by the `-S` parameter to `fastp`. If you would like to adjust the number of reads per split pair, edit the variable `split` within `Scripts/split_fastq_make_input.sh`. Note that `-S` adjusts the number of lines, so set `split` to the number of reads times 4. 

A split fastq pair containing 2 million read pairs (4 million reads total) on 12 CPU takes aproximately 2 minutes to align (human, T2T reference genome). The same data using 500,000 read splits requires around 1 minute. Creating split sizes that are too small can reduce efficiency due to the overhead of tool and reference index loading. 

Make inputs: 
```
bash Scripts/split_fastq_make_input.sh
```





### Notes on fastp
- The terminal files will be smaller than the split size, because the input fastq is unlikely to be equally divisable by the split value
- The output files will have a numeric prefix added by fastp. These are not always perfectly numeric ascending, ie you may have files `1.<fastq>.gz`, `2.<fastq>.gz`, `4.<fastq>.gz`. This is not an error. There is a checker script (4) inlcuded in this repository to ensure accurate splitting. 

## 4. Split fastq check 

## 5. Align split fastq

## 6. Create final BAMs (merge, mark duplicates, sort, index)

## 7. BAM QC

## 8. BAM QC multiQC

## 9. Create per sample gVCF

## 10. Joint genotype 
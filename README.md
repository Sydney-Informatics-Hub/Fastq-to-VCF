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
	- If you have fastq with '1' and '2' pair designation instead of 'R1' and 'R2', please rename/symlink to 'R1' and 'R2' 
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
Some steps are parallel by sample, and other steps are parallel by fastq ("scatter gather parallelism"). Alignment is executed after first splitting the fastq up into smaller pairs, to enable a much higher degree of parallelisation than simply aligning the fastq pairs as-is.  Only the MultiQC and final joint genotyping steps are executed as single (not parallel) jobs. 

For the parallel jobs, there are 3 workflow scripts per step:

1. `<stepname>_make_input.sh`: This script is executed on the login node with `bash`, and creates the input file required to parallelise the tasks. Each line in the output file `Inputs/<stepname>.inputs` contains the details for one parallel task such as sample ID, fastq, reference, etc. The PBS script (2) will launch the task script (3) once for every line in this 'inputs' file. Any changes regarding the inputs (such as reference sequence name) should be made in this script; no parameter changes should be required in the PBS (2) or task(3) script. 
2. `<stepname>_run_parallel.sh`: This script is submitted with `qsub` and runs the parallel job. Users will need to edit the NCI project code, `lstorage` directory, and resource requests. Note that the requests for the job are for the *whole* job, not for each single task. The variable `NCPUS` within the script body sets the number of CPUs that are allocated to each single task. Tasks may be executed all at once (eg 4 NCPUs per task, 24 tasks, running on 4 x 24 = 96 CPUs). If the total number of CPUs requested for the job is less than the number required to run all at tasks at once, the job wil simply assign tasks to CPUs in the order in which they appear in the inputs list, until all taks are run, or walltime is exceeded. For jobs where all tasks are expected to have similar walltime, requesting the number of total CPUs such that all tasks can be run at once (up to the Gadi queue limits) is reasonable. For jobs where unequal walltimes are expected, for example in cancer studies where tumour has greater coverage than normal samples, size-sorting the inputs largest to smallest or separating the job into separate batches with different inputs lists and walltimes will provide better CPU and KSU efficiency.
3. `<stepname>.sh`: This is the task script that contains the commands required to run the job. It is launched once per task by the PBS script (2) and is not submitted directly by the user. There should not be need to edit this script unless changes to the actual analysis task are warranted. 

# Benchmarking 

SIH workflows aim to provide benchmarking metrics and resource usage guidelines. At the time of writing (uly 31 2024) this workflow is in its infancy so these details are not yet available. They will be added over time. 

Parallel workflows always benefit from benchmarking. This extra workload at the start will save you time and KSU in the long run. At minimum, it is recommended to benchmark the alignment step, which uses the most KSU out of the whole workflow. The most efficient alignment threads and walltime per task will differ depending on the fastq split size, and will also vary somewhat between datasets, depending on reference genome quality, raw data quality, sample genetic complexity, etc. A starting split size of 10 million reads (split value of 40000000 lines) is a good starting point for benchmarking alignment against your indexed reference genome with 4, 6, 8 or 12 CPUs per alignment task.

The duplicate marking and sorting step should also be tested on one sample (typically the largest BAM) to establish compute requirements for that step that cannot be parallelised via splitting. 

We plan to develop a workshop on benchmarking bioinformatics workflows, but in this [benchmarking template](https://github.com/Sydney-Informatics-Hub/Gadi-benchmarking) may be useful. 

Compute resource usage summary and CPU efficiency calculations can be obtained using this [Gadi usage report](https://github.com/Sydney-Informatics-Hub/HPC_usage_reports/blob/master/Scripts/gadi_usage_report.pl) script. To use, download a copy of the script, change into the directory where your PBS logs are saved, and run the script with perl. 


# Logs

Tool logs are created into the `Logs` directory, for example the align step will create per-task logs into `Logs/BWA`. 

PBS logs are written to `PBS_logs`. 


# Run the workflow

## 0. Index the reference genome

The reference fasta to index should be within (or symlinked to) the `./Reference` directory. 

This step need only be done once per reference. If previously generated indexes for [`bwa-mem2`](https://github.com/bwa-mem2/bwa-mem2) and [`SAMtools`](https://github.com/samtools/samtools)(with the same tool versions) are available, copy or symlink them to the `./Reference` directory along with the fasta. They must all have the same filename prefix. 

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

### Fastq split size

The number of *lines* per output fastq file is governed by the `-S` parameter to `fastp`. If you would like to adjust the number of reads per split pair, edit the variable `split` within `Scripts/split_fastq_make_input.sh`. Note that `-S` adjusts the number of lines, so set `split` to the number of desired reads per split fastq times 4. 

A split fastq pair containing 2 million read pairs (4 million reads total) on 12 CPU takes aproximately 2 minutes to align (human, T2T reference genome). The same data using 500,000 read splits requires around 1 minute. Creating split sizes that are too small can reduce efficiency due to the overhead of tool and reference index loading. Since the RAM required for BWA-mem2 is higher than for BWA-mem1, out-of-memory failures can occur when requesting small CPU per task values. For this reason, we recommend splitting the fastq to 10 million reads, ie setting `-S 40000000` within the `fastp` command. 10 million paired-end reads on 12 CPU on Gadi's `normal` nodes requires ~ 40 GB RAM and 14-15 minutes per task. The alignment step size sorts the split fastq to ensure that split files created from the end of large input fastqs are processed last, thus maximising CPU efficiency.  

Apart from adjusting the value of `split`, no other edits are required to the `make_input` script. 

### Make parallel inputs file
```
bash Scripts/split_fastq_make_input.sh
```
### Edit the PBS script 

Edit `Scripts/split_fastq_run_parallel.pbs`: 

- `PBS -P <NCI poject code>`
- `PBS -lstorage` - specify all required NCI storage paths eg `-l storage=<scratch/a00+gdata/xy11+massdata/a00>`
- `PBS -l ncpus=` - adjust this based on your number of fastq pairs to be split. Each split task is assigned 4 CPU. Eg 100 fastq pairs = 100 X 4 CPU = 400 CPUs = 400/48 CPUs per normal node = 8.3 nodes = round up to 9 nodes = 48 X 9 = 432 CPUs.   
- `PBS -l mem=` - for ncpus < 48, set to 4 x the number of ncpus. For whole nodes, request number of nodes X 190 GB mem. 
- `PBS -l walltime=` - adjust based on size of input fastq (assess based on largest pair). A safe starting point is 2 hours for a 30X sample not multiplexed across lanes ie only one large pair of fastq per sample. 

### Submit
```
qsub Scripts/split_fastq_run_parallel.pbs
```

### Check 
- Output is split fastq pairs in `./Fastq_split`. These will have the same filename suffix as the original, with a numerber added at the start. 
- Exit status 0 and appropriate walltime in `PBS_logs/split_fastq.o`
- All tasks have "exited with status 0" in `PBS_logs/split_fastq.e`:

```
grep "exited with status 0" PBS_logs/split_fastq.e | wc -l
```

- The number should match the number of fastq in your input list. If not, use grep to obtain the failed tasks, make a separate input list, and resubmit those tasks, correcting any errors or revising the walltime as required. 


### Notes on fastp
- The terminal split files will be smaller than the specified split size, because the input fastq is unlikely to be equally divisable by the split value
- The output files will have a numeric prefix added by fastp. These are not always perfectly numeric ascending, ie you may have files `1.<fastq>.gz`, `2.<fastq>.gz`, `4.<fastq>.gz`. This is not an error. There is a checker script (step 4) inlcuded in this repository to ensure accurate splitting, ie that the read count of input matches the sum read count of all outputs. 

## 4. Split fastq check 

This ensures you have equal reads in your R1 and R2 as well a that the splitting process has not introduced any errors. 

It is a parallel script, yet there is need to create a new inputs file, as the `./Inputs/split_fastq.inputs` file from the splitting step is used. 

### Submit

Adjust the PBS directives as described for previous parallel steps, accomodating for 12 CPU per parallel task, then submit:

```
qsub split_fastq_check_fastq_input_vs_split_output_run_parallel.pbs
```

### Check
- Check the PBS logs `./PBS_logs/check_split_fastq.o ` and `./PBS_logs/check_split_fastq.o ` as described for previous parallel steps
- Check the log files in `./Logs/Check_fastq_split`:  

```
grep "has passed all checks" ./Logs/Check_fastq_split/* | wc -l
```

- The number should match the number of fastq pairs in your input list. If not, review the logs to isoalt ethe source of error, use grep to obtain the failed tasks, make a separate input list, and resubmit those tasks, correcting any errors or revising the walltime as required. 

## 5. Align the split fastq

Alignment is performed with [`bwa-mem2`](https://github.com/bwa-mem2/bwa-mem2) which is up to 2X faster than `bwa-mem1` with identical results. The K value is applied to ensure thread count does not affect alignment output due to random seeding.

This is the first step in the workflow that requires your sample configuration file. Please ensure this matches the format described in [Example configuration file](#example-configuration-file). 

### Make parallel inputs file

First, open the scipt and update the variable `ref` to your reference fasta, eg `ref=./Reference/mygenome.fasta`. Check that the regex for the fastq pair matching matches your reads and adjust as required. Expected filename format is <prefix>_R1.fastq.gz, <prefix>_R1.fq.gz, <prefix>.R1.fastq.gz or <prefix>.R1.fq.gz.

Flowcell and lane are extracted from Illumina-formatted read ID. If your read IDs do not match this format, please adjust the regex as required. Allowance is made for SRA-derived reads by checking for read ID beginning with '@SRR' and using 'unknown' for flowcell and lane.  

Save the script and provide the sample configuration file name as a command line argument: 
```
bash Scripts/align_make_input.sh <samples.config>
```
### Edit the PBS script 

Edit `Scripts/align_run_parallel.pbs`: 

- Edit the project code and lstorage directives
- `PBS -l ncpus=` - adjust this based on your number of alignment tasks/split fastq pairs and the number of CPus per alignment task. Eg 500 split fastq pairs and 12 CPUs per alignment task = 500 X 12 = 6000 ncpus = 125 Gadi normal nodes. If you have determined from benchmarking that a split fastq of your chosen size required 15 minutes to align to your genome on 12 CPU, this would be 125 nodes for 15 minutes. This is reasonable, however you may also choose to halve the number of nodes and double the walltime requested, or quarter the number of nodes and quadruple the walltime requested, etc etc, to process the list of alignment tasks in a way that not all tasks are allocated simultaneously. For large cohorts, this is typically the better way to proceed, as we can quickly hit the upper limit of 432 maximum normal nodes per job. For very large cohorts, dividing the `Inputs/align.inputs` list into batches and submitting multiple parallel jobs may be required. Given that some loss of efficiency is typically observed at scale, ensure to add some walltime buffer, eg request 45 minutes if you expect a walltime of 30 minutes. Tasks that fail on walltime can be identified and resubmitted.   
- `PBS -l mem=` - for ncpus < 48, set to 4 x the number of ncpus. For whole nodes, request number of nodes X 190 GB mem. 
- `PBS -l walltime=` - adjust based on the number of alignment tasks, walltime per task, desired walltime buffer, and `PBS -l ncpus=` 
-`NCPUS` variable: this is the number of CPU assigned to each parallel task. It is not a PBS directive. You should have determined the optimal split size and CPUs per alignment task from prior benchmarking. The default in this script is 12. Recommended values are 4, 6 or 12. This is based on the NUMA architecture of the Gadi normal (Cascade Lake) nodes as well as the goal of parallelising many smaller tasks for higher throuhgput rather than fewer larger tasks. 

### Submit

```
qsub Scripts/align_run_parallel.pbs
```

### Check 
- Check the PBS logs `./PBS_logs/align.o` and `./PBS_logs/align.e` as previosuly described, ensuring that the number of tasks that "exited with status 0" is equal to the number of alignment tasks in the `./Inputs/align.inputs` file. 
- Note that for a job that is killed due to exceeding walltime, some tasks may not appear in the `./PBS_logs/align.e` file. In this case, additional methods will be required to extract the tasks that are needing to be resubmitted. Future updates to this workflow will include a check script for this. 
- Alignment output will be `./Align_split/<prefix>.nameSorted.bam`, one BAM per input split fastq pair. 
- `./Logs/Align_split_error_capture` should be empty for a successful job. This will report any BAMs that fail `SAMtools quickcheck` or are missing key completion mesages in the `BWA` logs. As per the PBS log checking, if the job fails on walltime, relying on this error check alone may miss some failed tasks that were not submitted before the job terminated.


## 6. Create final BAMs (merge, mark duplicates, sort, index)

This job is parallel by sample, so the number of tasks will be equal to the number of samples. 

It merges (gathers) the split (scattered) alignment files, completing the scatter-gather parallelism enabled by physically splitting the fastq. Merging is performed with [`SAMBAMBA`](https://github.com/biod/sambamba), duplicate marking with [`SAMBLASTER`](https://github.com/GregoryFaust/samblaster) and sorting and indexing with [`SAMtools`](https://github.com/samtools/samtools). 

### Make parallel inputs file
 
```
bash Scripts/final_bam_make_input.sh <samples.config>
```
### Edit the PBS script 

Edit `Scripts/final_bam_run_parallel.pbs`: 

- Edit the project code and lstorage directives as previosuly described
- Adjust directives for ncpus and mem according to the number of samples
- If you are unsure of the resources required, running this script on your largest sample with generous limits is a helful benchmark to perform
- As a starting point, 30X sample on 24 CPU normal nodes (allowing 4 GB mem per CPU) completed in 85 minutes
- For very large samples (eg 90X), increasing to one node per sample (ie set NCPUs variable to 48) and manually editing the `Scripts/align.sh` task script to apply 36 threads to SAMtools sort may be required. Alternatively, run all samples on the Gadi Broadwell nodes (`normalbw` queue) setting the NCPUs variable to 48 and requesting 9 GB RAM per CPU. The Broadwell nodes are older and slower than the newer Cascade Lake nodes on the `normal` queue, but can provide more RAM per CPU. Using the Broadwell nodes in these cases will probably require more walltime but result in overall less KSU compared to allowing one whole Cascade Lake node per sample. 

## 7. BAM QC

There are many tools for running QC on BAM files. We have a beta nextflow [repository BamQC-nf](https://github.com/Sydney-Informatics-Hub/bamQC-nf) that has modules for `SAMtools stats`, `SAMtools flagstats`, `Qualimap` and `Mosdepth`. Qualimap gives very comprehensive results however is resource intensive so may be prohibitively costly for large cohorts. `SAMtools stats` gives detailed output for a very small resource footprint. 

The table below shows the optiomal benchmarked resources for the NA12890 Platinum Genomes sample:

| Job                | CPU | Queue    | Mem_requested | Mem_used | CPUtime_mins | Walltime_mins | CPU_Efficiency | Service_units |
|--------------------|-----|----------|---------------|----------|--------------|---------------|----------------|---------------|
| samtools_flagstats | 4   | normalbw | 36.0GB        | 35.19GB  | 33.93        | 8.75          | 0.97           | 0.73          |
| samtools_stats     | 2   | normal   | 8.0GB         | 8.0GB    | 56.8         | 31.67         | 0.9            | 2.11          |
| mosdepth           | 2   | normal   | 8.0GB         | 8.0GB    | 18.95        | 11            | 0.86           | 0.73          |
| qualimap           | 14  | normalbw | 126.0GB       | 98.14GB  | 319.57       | 82.18         | 0.28           | 23.97         |

Users are encouraged to either use [repository BamQC-nf](https://github.com/Sydney-Informatics-Hub/bamQC-nf) ***or*** take a copy of a trio of scripts from one of the parallel steps of this workflow and modify to run the desired BAM-QC tool, using the above benchmarks as a guide for setting up resources. 

## 8. BAM QC multiQC

To run multiqc over BAM-QC outputs, simply specify the BAM-QC results directories as well as the desired output directory. For large cohorts, it may be necessary to submit this to the scheduler. For smaller cohorts, running on the login node is fast and light enough. 

```
module load multiqc/1.9
multiqc <bamqcdir1> <bamqcdir2> -o <BAM-QC-out>
```

## 9. Create per sample gVCF

This step uses [DeepVariant](https://github.com/google/deepvariant) ([Poplin et al 2018](https://www.nature.com/articles/nbt.4235)) deep learning based variant caller to produce gVCF per sample. You do not need to install DeepVariant on Gadi as it is available within the [NVIDIA Parabricks](https://docs.nvidia.com/clara/parabricks/latest/index.html) package, which is available as a global app on Gadi. 

Unlike previous steps where `nci-parallel` is used to parallelise tasks, this step uses a wrapper/run script to launch each sample as a separate job. This is due to the use of GPU, a more scarce resource compared to the normal node CPU. 

- Within `./Scripts/deepvariant_run_loop.sh`, update the variable `ref` to the name of your reference fasta within the `./Reference` directory
- Within `./Scripts/deepvariant.pbs`, update your project code at `#PBS -P` and scratch/gdata paths at `#PBS -lstorage` directives 

Save both scripts, then submit:
```
bash ./Scripts/deepvariant_run_loop.sh <config>
```

As the script loops over your config, it will submit `./Scripts/deepvariant.pbs` separately for each sample in your config. You should expect to see a message `Submitting <labSampleID>` followed by a job ID for each sample. 

Ensure to check all job logs in `./PBS_logs/DeepVariant` and `./Logs/DeepVariant` to ensure exit stauts zero and no error messages, and that all samples have a gVCF of expected size in the `./gVCF` output directory.

## 10. Joint genotype 

A jointly genotyped VCF is created for all samples in the cohort using [GLNexus](https://github.com/dnanexus-rnd/GLnexus) ([Fin et al 2018](https://github.com/dnanexus-rnd/GLnexus)). 

This final step includes one script `./Scripts/joint_genotype.pbs`. 

You don't need to install GLNexus as it is readily available as a BioContainer. 

- Change directory to where you would like your GLNexus tool container to be saved. We recommend 'gdata'.  Note that if you have singularity environment variables set, this may affect where the container is saved to.
- Run the following commands on the Gadi login node to pull the docker container as a singularity image file:

```
module load singularity
singularity pull docker://quay.io/biocontainers/glnexus:1.4.1--h17e8430_5
```

You may wish to check [quay.io](https://quay.io/repository/biocontainers/glnexus?tab=tags) for a newer tool version. 

Then edit `./Scripts/joint_genotype.pbs`:

- Update directives `#PBS -P` and `#PBS -lstorage`
- Update the variable `glnexus_container` to the image file you just pulled. Ensure the storage location is covered by your `lstorage` list
- Update the `cohort` variable to the prefix of your cohort. This will be used to name your output VCF

Note that the script includes `--config DeepVariantWGS` within the command. This parameter instructs which presets to use depending on the data, eg `DeepVariantWGS` for whole genome sequencing and `DeepVariantWES` for whole exome sequencing. 

Save the script and submit with:

```
qsub ./Scripts/joint_genotype.pbs
```

Example run time: 55 minutes on 6 `hugemem` CPU for a cohort of 25 30X mammalian WGS. 

Expected output is a gzipped VCF in `./Joint_VCF` with the name of your cohort as prefix, and a tabix index. 

Check the job completed successfully by reviewing logs in `./Logs/GLnexus` as well as `./PBS_logs/joint_genotype.o` and `./PBS_logs/joint_genotype.e`. 



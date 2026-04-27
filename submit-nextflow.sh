#!/bin/bash -l
# ============================================================
# SGE job scheduler directives
# ============================================================
#$ -m be           # email when job Begins and Ends
#$ -l h_rt=48:0:0  # hard runtime limit (4h for test, 48h for full)
#$ -l mem=32G      # memory per slot (16G for test, 32G for full)
#$ -j y            # merge stderr into stdout
#$ -N PROJECT_NAME-rnaseq  # job name — change to reflect test/full
#$ -wd /home/USER/Scratch/projects/PROJECT_NAME  # working directory
#$ -pe smp 4       # parallel environment: 4 CPU slots (always needed for nextflow)

# Note: assumes nextflow is loaded via ~/.bashrc and ~/.bash_profile

## set main dir
PRJDIR=/home/USER/Scratch/projects/PROJECT_NAME
mkdir -p $PRJDIR/logs

# ============================================================
# Determine whether this is a test or full run based on job name
# The job name is set with -N above; include "test" for a test run
# ============================================================
if [[ "$JOB_NAME" == *test* ]]; then
    echo "Running test."
    TESTING=T
else
    echo "Running full script. Output is sent to logs/nextflow_${JOB_ID}.log"
    TESTING=F
fi


# ============================================================
# TEST RUN: uses nf-core's built-in test profile and test data
# ============================================================
if [ $TESTING == "T" ]; then
    /usr/bin/time --verbose nextflow run nf-core/rnaseq -r 3.21.0 -profile test,singularity \
    --outdir $PRJDIR/test \
    &> $PRJDIR/logs/nextflow_${JOB_ID}.log
fi 

# ============================================================
# FULL RUN: runs the pipeline on real data
# ============================================================
if [ $TESTING == "F" ]; then

    # Path to reference genome directory — update for your genome/system

    genDir=${PRJDIR}/input/genome/GCF_000195955.2 ##### update this to the location of the genome files (fasta and gtf) on your system

    ### run pipeline
    /usr/bin/time --verbose nextflow run nf-core/rnaseq -r 3.21.0 \
    -profile ucl_myriad \   # HPC-specific config profile
    -resume \               # resume from cached steps if restarting
    -work-dir ${PRJDIR}/work \
    --remove_ribo_rna \     # filter out ribosomal RNA reads
    --max_memory "32.0GB" \
    --pseudo_aligner salmon \   # use Salmon for fast pseudo-alignment
    --skip_dupradar \       # skip duplicate rate analysis
    --input ${PRJDIR}/samplesheet.csv \
    --outdir ${PRJDIR}/output \
    --fasta ${genDir}/GCF_000195955.2_ASM19595v2_genomic.fna \
    --gtf ${genDir}/genomic.gtf.gz \  # use --gff instead if you have a GFF file
    &> ${PRJDIR}/logs/nextflow_${JOB_ID}.log


fi 

## additional stuff can be added in config:
# -c ${PRJDIR}/code/nextflow-config/nf.config \

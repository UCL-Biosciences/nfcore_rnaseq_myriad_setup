#!/usr/bin/env bash
# Script to create a samplesheet.csv file for use with nf-core pipelines (rnaseq)
# Usage: bash create-samplesheet.sh /path/to/fastqs [strandedness]
# Strandedness defaults to auto

## the first argument is the dir holding all fastq files. If the argument isn't given, will use the current working directory
DIR=${1:-.}
# the second arg is strandedness. If not given, will add "auto" for all files.
STRAND=${2:-auto}

## main project dir and where to create samplesheet.csv
PRJDIR=/home/USER/Scratch/projects/PROJECT_NAME
OUT=${PRJDIR}/samplesheet.csv

# create output file with just column headers
echo "sample,fastq_1,fastq_2,strandedness" > "$OUT"

### in the $DIR, loop through all forward read files
for r1 in "$DIR"/*_R1*.fastq.gz "$DIR"/*_1.fastq.gz; do

  ## make sure $r1 is a real file
  [[ -f "$r1" ]] || continue
	
  ## replace the _R1 with _R2 to get the name of reverse reads file 
  ## ${variable/pattern/replacement} 
  r2="${r1/_R1/_R2}"

  ## if the pattern is not _R1 and _R2, then the $r2 naming won't work
  ## and $r2 will still equal $r1
  ## in which case, we try the other naming convention: replace _1.fastq.gz with _2.fastq.gz
  [[ "$r2" == "$r1" ]] && r2="${r1/_1.fastq.gz/_2.fastq.gz}"

  ## horrible sed to to get the sample ID from the fastq file name
  sample=$(basename "$r1" .fastq.gz | sed 's/_R1.*//;s/_1$//')

  ## finally append the sample id, forward read file path, reverse read file path, and strand to the samplesheet.csv file.
  echo "${sample},$(realpath "$r1"),$(realpath "$r2" 2>/dev/null),${STRAND}" >> "$OUT"

done

echo "Written to $OUT"
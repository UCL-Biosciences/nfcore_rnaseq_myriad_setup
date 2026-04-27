# nfcore_rnaseq_myriad_setup
Examples of a setup for nfcore/rnaseq on myriad. This has worked for me but it is not meant to be comprehensive or the best example. Feedback and contributions of course welcome!

Covers three steps:
1. Set up nextflow on myriad
2. copy files from RDSS and check md5 hashes match
3. Create samplesheet.csv required for pipeline
4. submit the nextflow script.

For more info on UCL HPCs, see [here](https://github.com/UCL-Biosciences/Biosciences-Comp-Support/blob/main/UCL_comp_guides/high_performance_compute_at_UCL.md).

Here is full rna seq info at [nf-core](https://nf-co.re/rnaseq).

## Nextflow setup
Set up nextflow on myriad following [these instructions](https://nf-co.re/configs/ucl_myriad/). Note you need to replace the XX.XX.X in the NXF_VER

## Copy files and check hashes
Script file: [cp.sh](https://github.com/UCL-Biosciences/nfcore_rnaseq_myriad_setup/blob/main/cp.sh)

Example for copying reads from RDSS to your scratch space. Must change `$FROM` and `$TO` paths to match you setup.

Assuming you have `.md5` files (one per fastq), it will loop through them and confirm the md5 hashes match. There are shorter ways to do this but I think this way is easier to follow.

The `cut $file -f 1 -d ' '` lines specify which columns to take - you might need to edit this.

## Create Samplesheet
Script file: [create-samplesheet.csv](https://github.com/UCL-Biosciences/nfcore_rnaseq_myriad_setup/blob/main/create-samplesheet.sh)

You need to set up the samplesheet.csv. (see [usage](https://nf-co.re/rnaseq/3.25.0/docs/usage) for info). This just tells the pipeline where the files are for each sample. The code I used to do it is attached in [create-samplesheet.csv](https://github.com/UCL-Biosciences/nfcore_rnaseq_myriad_setup/blob/main/create-samplesheet.sh). Is a bit ugly but I find it quick to create samplesheet.

You run it from the command line: `bash create-samplesheet.sh /path/to/fastqs [strandedness]`

The first argument is the dir holding all fastq files. If the argument isn't given, will use the current working directory: `DIR=${1:-.}`

The second arg is strandedness. If not given, will add "auto" for all files: `STRAND=${2:-auto}`

For the dir specified, it:
1. makes a samplesheet.csv file with just column headers
2. finds all forward read files (= filenames contain _1 or _R1) and loops through
3. replaces the _1 or _R1 with _2 or _R2
4. extracts sample name based on pattern match. you might need to change depending on your file name formats
5. appends the required info to the samplesheet file.

## Run pipeline
Script file: [submit-nextflow.sh](https://github.com/UCL-Biosciences/nfcore_rnaseq_myriad_setup/blob/main/submit-nextflow.sh)

### Testing
nf-core pipelines have a handy testing function that allows you to make sure the setup works with example data before running the full job. In this script, the test for nf-core/rnaseq will automatically run if you include "test" (case sensitive) in the job name, set with option `#$ -N PROJECT_NAME-rnaseq`.  So if you add `#$ -N PROJECT_NAME-rnaseq-test` to the top of your job script, the script will run the test and confirm whether the nextflow/nf-core setup is correct.

### Full Job
To run the pipeline, makesure "test" is not in the job name. The main code is towards the bottom of the `submit-nextflow.sh` script. Some info about the arguments:

`nextflow run nf-core/rnaseq -r 3.21.0` # nextflow run is the command, the rest specifies the pipeline to use

`-profile ucl_myriad` # settings required to run on myriad

`--input ${PRJDIR}/samplesheet.csv `# this is important, see above.

`--outdir ${PRJDIR}/output` # where to write output
   
`--fasta ${genDir}/GCF_000195955.2_ASM19595v2_genomic.fna` # link to local version of reference genome sequence in fasta format

`--gtf ${genDir}/genomic.gtf.gz`  # genome annotation. Can be gtf or gff but note the flag changes depending on whether you have a gff or gtf file # 

 `--remove_ribo_rna` # remove ribosomal RNA

`--max_memory "32.0GB"` # STAR requires quite a lot of mem. Sometimes 64GB but 32GB worked with your data

`--pseudo_aligner salmon` # to use salmon as the pseudo aligner. By default, it also seems to run with STAR for alignment, then salmon for quantification

`--skip_dupradar` # dupradar wasn't working so I removed. Not sure if needed

`&> ${PRJDIR}/logs/nextflow_${JOB_ID}.log` # this is where the job info (including error messages) is sent. I find it better to link to the job_id so I know which job failed and why.




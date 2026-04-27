#!/bin/bash
#$ -S /bin/bash
#$ -l mem=1G
#$ -l h_rt=4:00:00
#$ -cwd
#$ -j y
#$ -m be # email to be notified when the job begins and ends


FROM=/rdss/PATH/TO/YOUR/RAW/READS
TO=/home/USER/Scratch/projects/PROJECT_NAME/input/raw_tx

mkdir -p $TO

## rsync all files in the $FROM directory
rsync -av --progress $FROM/ $TO/

### ASSUMES YOU HAVE COPIED OVER MD5 FILES FOR ALL FASTA/FASTQ FILES!
## loop through all md5 files
for file in $TO/*md5; do 
	
    ### get the hash and the file name
    md5sum=$(cut $file -f 1 -d ' ')
    filename=$(cut $file -f 3 -d ' ')

    echo $md5sum
    echo $filename

    ### get the original md5 hash
    og_md5sum=$(cut $FROM/$filename.md5 -f 1 -d ' ')

    ### compare them - if they don't match, exit the job with an error.
    if [ "$md5sum" == "$og_md5sum" ]; then
        echo "MD5 sums match for $filename"
    else
        echo "MD5 sums do NOT match for $filename" >&2
        exit 1
    fi

done
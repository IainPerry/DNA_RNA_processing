# Trimming
After merging or linking the raw FASTQ files, we move to the trimming stage.

We use [fastp](https://github.com/OpenGene/fastp) to perform quality trimming and adapter removal.
This step improves the overall quality of the reads and removes low-quality regions and sequencing artifacts before mapping.
We can talk about the nuances of quality trimming elswhere, but fastp is ***fast*** and it is good.

The trimming step is run using Singularity containers for reproducibility, and is submitted as a batch job using SLURM.

### Logic
We set WAITFOR, this is important for later but we then check if SKIPQCTRIM=TRUE, if so, trimming is skipped.
Otherwise, the script loops through each sample and:
 + Waits for an available job slot `wait_for_slot`.
 + Submits a SLURM job for trimming using sbatch.
 + The trimming is performed inside a Singularity container using fastp.
 + Different commands are used depending on single-end (SE) or paired-end (PE) mode.
```
WAITFOR=":1"
if [ "$SKIPQCTRIM" = "TRUE" ]; then
    echo "$(date '+%F %T') - Skipping Trimming" >> $log_file
else
    for i in $SamplesRaw; do
       wait_for_slot
```
We  let the log file know we are starting trimming for each sample.
```
        echo "$(date '+%F %T') - Starting trimming job ${i}" >> $log_file
```
### sbatch 
Our slurm script is actually wrapped below, but first we want to give slurm all of the details we need.
The wrapped slurm script starts after `--wrap="` and ends with `"`
The whole slurm sbatch command is set as a variable function named ***RETVAL***
```
        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=2 --time="0-2:00" \
            --error="$LOGS/trim/slurm_${i}_trim.err" --output="$LOGS/trim/slurm_${i}_trim.out" \
            --wrap="module load $SINGULARITY
```

### fastp script
The actual slurm script first loads singularity then runs the fastp container using either PE or SE options.
We set inputs `--in1` `--in2`
We set outputs `--out1` `--out2`
We define the threads
We define output files we want. In this case bothe html and json files.
```
if [ "$RUNTYPE" = "PE" ];
        then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF  fastp \
                  --in1 $TMP/${i}_M_F.fq.gz \
                  --in2 $TMP/${i}_M_R.fq.gz \
                  --out1 $TRIM/${i}_trimmed_F.fq.gz \
                  --out2 $TRIM/${i}_trimmed_R.fq.gz \
                  --thread 2 \
                   -h $LOGS/trim/${i}_fastp.html \
                   -j $LOGS/trim/${i}_fastp.json

        else singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF  fastp \
                  --in1 $TMP/${i}_M_F.fq.gz \
                  --out1 $TRIM/${i}_trimmed_F.fq.gz \
                  --thread 2 \
                   -h $LOGS/trim/${i}_fastp.html \
                   -j $LOGS/trim/${i}_fastp.json
fi

")


        JOBID=$(echo $RETVAL | sed "s/Submitted batch job //")
        WAITFOR="${WAITFOR}:${JOBID}"
    done
    echo "$WAITFOR"
fi
```

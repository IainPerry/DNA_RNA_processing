# DNA Mapping
### Logic
And just like RNA Mapping...
```
WAITFOR2="$WAITFOR2:1"
if [ "$SKIP_DNA_MAP" = "TRUE" ]; then
    echo "$(date '+%F %T') - Skipping DNA Mapping"  >> $log_file
else
    for i in $SamplesRaw; do
        wait_for_slot
        echo "$(date '+%F %T') - Starting DNA Mapping job ${i}" >> $log_file

         if [ "$Species" = "Human" ];
            then BWAgenome="${BWAgenomeH}"
            else BWAgenome="${BWAgenomeM}"
         fi
echo "Waitfor is: $WAITFOR"
        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time="0-6:00" \
            --error="$LOGS/bam/slurm_${i}_map.err" --output="$LOGS/bam/slurm_${i}_map.out" --dependency=afterok${WAITFOR} \
            --wrap="module load $SINGULARITY
```
### BWA
Unlike in STAR, the bwa command is somewhat simpler, and yet more complex.
First we map (either SE or PE):
+ we only need to define the process `bwa mem`.
+ the number of threads `-t 8`
+ The genome we want to map to `$BWAgenome`
+ The fastq reads we want to map `"$TRIM/${i}_trimmed_F.fq.gz" "$TRIM/${i}_trimmed_R.fq.gz"`
+ The output, which in this case is just a sam file `> "$BAM/${i}.sam"`
```
if [ "$RUNTYPE" = "PE" ];
         then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $BWA_SIF bwa mem \
                   -t 8 \
                   $BWAgenome \
                   "$TRIM/${i}_trimmed_F.fq.gz" "$TRIM/${i}_trimmed_R.fq.gz" \
                   > "$BAM/${i}.sam"
         else singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $BWA_SIF bwa mem \
                   -t 8 \
                   $BWAgenome \
                   "$TRIM/${i}_trimmed_F.fq.gz" \
                   > "$BAM/${i}.sam"
fi
```
Now we need to convert the sam file to a bam using samtools
+ we define the process `samtools sort`
+ the number of threads `-@8`
+ the output `-o` which is a bam file
+ the input sam
  
```
              singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $SAMTOOLS_SIF samtools sort \
                   -@ 8 \
                   -o  "$BAM/${i}.bam" \
                   "$BAM/${i}.sam"
```
Unlike STAR, duplicates do matter, particually when variant calling. for this we use our third tool, Picard.
+ we define the process `java -jar $PICARD Mark Duplicates`
+ we define the input bam
+ we define the output bam
+ we define metrics for looking at later in the logs
+ we will index later, so we don't create an index
+ we want to mark, not remove duplicates. Some callers want to see what could be a duplicate.
+ we keep it quiet 
```
              singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $PICARD_SIF \
                   java -jar $PICARD MarkDuplicates \
                   I="$BAM/${i}.bam" \
                   O="$BAM/${i}_dedup.bam" \
                   M="$LOGS/${i}_dedup_metrics.txt" \
                   CREATE_INDEX=false \
                   REMOVE_DUPLICATES=False \
                   VALIDATION_STRINGENCY=SILENT

rm $BAM/${i}.sam
echo "$(date '+%F %T') - Submitted job with ID: $job_id" >> $log_file
")

      JOBID=`echo $RETVAL | sed "s/Submitted batch job //"`
      WAITFOR2=`echo "${WAITFOR2}:${JOBID}"`
   done
   echo "$WAITFOR2"
fi
```

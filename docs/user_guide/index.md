# Indexing

## Logic
This should really be run for both RNA and DNA, it includes stats as part of the step.
We first want to set variables
```
WAITFOR3="$WAITFOR3:1"
if [ "$SKIPINDEX" = "TRUE" ];
  then echo "$(date '+%F %T') - Skipping Indexing" >> $log_file
else
      for i in $SamplesRaw; do
          wait_for_slot
          echo "$(date '+%F %T') - Starting Indexing job ${i}" >> $log_file

         if [ "$Species" = "Human" ];
            then STARgenome="$STARgenomeH"
                 GENCODE="$GENCODEH"
            else STARgenome="$STARgenomeM"
                 GENCODE="$GENCODEM"
         fi
```
Our sbatch gets a little more complicated with if statements to allow for identifying if its from STAR or BWA.

```
        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=2 --time=0-1:00 \
            --error="$LOGS/bam/slurm_${i}_index.err" --output="$LOGS/bam/slurm_${i}_index.out" --dependency=afterok${WAITFOR2} \
            --wrap="module load $SINGULARITY

        # Check for dedup BAM and index it
        if [ -f "$BAM/${i}_dedup.bam" ]; then
            echo "Indexing deduplicated BAM: ${i}_dedup.bam"
```
## Samtools
If its from bwa, we use samtools to index
```
            singularity exec --bind "$Base/:$Base/" --bind "$SIF_DIR/:$SIF_DIR/" "$SAMTOOLS_SIF" \
                samtools index -@ 2 "$BAM/${i}_dedup.bam"
```
## Qualimap
We then use qualimap to run some statistics on the bam files.
+ we define the command `qualimap bamqc`
+ we define the input bam
+ we define the gff with all the genomes features
+ we define the output
```

            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $QUALIMAP_SIF qualimap bamqc \
                -bam "$BAM/${i}_dedup.bam" -gff "${Base}/${STARgenome}${GENCODE}" -outdir $LOGS/bam/${i}_qualimap
        fi
```
And we do the same for STAR
```

        # Check for sorted-by-coords BAM and index it
        if [ -f "$BAM/${i}_mapAligned.sortedByCoord.out.bam" ]; then
            echo "Indexing sorted BAM: ${i}_mapAligned.sortedByCoord.out.bam"
            singularity exec --bind "$Base/:$Base/" --bind "$SIF_DIR/:$SIF_DIR/" "$SAMTOOLS_SIF" \
                samtools index -@ 2 "$BAM/${i}_mapAligned.sortedByCoord.out.bam"

            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $QUALIMAP_SIF qualimap bamqc \
                -bam "$BAM/${i}_mapAligned.sortedByCoord.out.bam" -gff "${Base}/${STARgenome}${GENCODE}" -outdir $LOGS/bam/${i}_qualimap
        fi
```
If neither exist then we dont need to be running this, so it kills the jobs for you to correct
```
        # Fail if neither exists
        if [ ! -f "$BAM/${i}_dedup.bam" ] && [ ! -f "$BAM/${i}_mapAligned.sortedByCoord.out.bam" ]; then
            echo "No BAM file found for $i!"
            exit 1
        fi
")

JOBID=`echo $RETVAL | sed "s/Submitted batch job //"`
WAITFOR3=`echo "${WAITFOR3}:${JOBID}"`
done
echo "$WAITFOR3"

fi
```

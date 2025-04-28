# Feature Counting

## Logic
Just like with all our scripts so far, the logic is defined at the beginning with wait for and dependencies. 
This will only be run for RNA data so we could put a kill command in if we really wanted
```
WAITFOR4="$WAITFOR4:1"
if [ "$SKIPFC" = "TRUE" ];
  then echo "$(date '+%F %T') - Skipping Feature Counts" >> $log_file
else
      for i in $SamplesRaw; do
         wait_for_slot
         echo "$(date '+%F %T') - Starting Feature Counts job ${i}" >> $log_file

         if [ "$Species" = "Human" ];
            then STARgenome="$STARgenomeH"
                 GENCODE="$GENCODEH"
            else STARgenome="$STARgenomeM"
                 GENCODE="$GENCODEM"
         fi

        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=4 --time=0-2:00 \
            --error="$LOGS/counts/slurm_${i}_FC.err" --output="$LOGS/counts/slurm_${i}_FC.out" --dependency=afterok${WAITFOR3} \
            --wrap="module load $SINGULARITY
```
## Featurecounts
Depending on the level we are interested in. i.e. counting at gene, transcript, or exon level. For most analysis gene is the right choice.
>! This section is currently under-developed for options. Really we need to add variables for define for paired or single end sequencing and strand specificity.
```

if [ "$CV" = "tc" ];
         then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FC_SIF featureCounts \
                    -p \
                    -s 4 \ 
                    --donotsort -B \
                    -t "exon" \
                    -g "transcript_id" \
                    -a ${STARgenome}${GENCODE} \
                    -o $COUNTS/${i}.tc.out \
                    $BAM/${i}_mapAligned.sortedByCoord.out.bam
                    
              cut -f1,7 "$COUNTS/${i}.tc.out" > $COUNTS/${i}.tc.out.tab
              sed -i 1,2d "$COUNTS/${i}.tc.out.tab"
```
Looking at the gene level...
+ we define the process `featureCounts`
+ we define this is paired end data
+ we define strand specificity. 4 indicates the library is stranded
+ we don't want to sort, as its already done
+ we specify features to count against are exons
+ we then group the counts against exons
+ we define the gtf feature file
+ we define the output
+ we define the input

```
elif [ "$CV" = "gn" ];
         then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FC_SIF featureCounts \
                    -p \
                    -s 4 \
                    --donotsort -B \
                    -t "exon" \
                    -g "gene_id" \
                    -a ${STARgenome}${GENCODE} \
                    -o $COUNTS/${i}.gn.out \
                    $BAM/${i}_mapAligned.sortedByCoord.out.bam
```
## Post processing
We then take feature count's output, which is a table of read counts for each gene, and select only the ones we want.
we then remove header info that we dont need.
```
              cut -f1,7 "$COUNTS/${i}.gn.out" > $COUNTS/${i}.gn.out.tab
              sed -i 1,2d "$COUNTS/${i}.gn.out.tab"


elif [ "$CV" = "ex" ];
         then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FC_SIF featureCounts \
                    -p \
                    -s 4 \
                    --donotsort -B \
                    -t "exon" \
                    -g "exon_id" \
                    -a ${STARgenome}${GENCODE} \
                    -o $COUNTS/${i}.ex.out \
                    $BAM/${i}_mapAligned.sortedByCoord.out.bam

              cut -f1,7 "$COUNTS/${i}.ex.out" > $COUNTS/${i}.ex.out.tab
              sed -i 1,2d "$COUNTS/${i}.ex.out.tab"

else
  echo "$(date '+%F %T') - Error in featureCounts" >> $log_file
fi
")


JOBID=`echo $RETVAL | sed "s/Submitted batch job //"`
WAITFOR4=`echo "${WAITFOR4}:${JOBID}"`
done
echo "$WAITFOR4"
```
fi

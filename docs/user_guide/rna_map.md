# RNA Mapping

### Logic
Just like with fastp, we run the job exacly the same.

```
WAITFOR2=":1"
if [ "$SKIP_RNA_MAP" = "TRUE" ]; then 
    echo "$(date '+%F %T') - Skipping RNA Mapping"  >> $log_file
else
    for i in $SamplesRaw; do
        wait_for_slot
        echo "$(date '+%F %T') - Starting RNA Mapping job ${i}" >> $log_file

         if [ "$Species" = "Human" ];
           then STARgenome="$STARgenomeH"
           else STARgenome="$STARgenomeM"
         fi
```

### WAITFOR
The main difference is we now have `--dependency` set in our sbatch command. Because we need fastp to have finished...
...we use slurms dependency to wait for a successful end of all job id's set in the WAITFOR set in fastp.
Once they have all completed, queued up rna_mappings can start.
It also sets its own WAITFOR for the next job in the pipeline.

```
        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time="0-6:00" \
            --error="$LOGS/bam/slurm_${i}_map.err" --output="$LOGS/bam/slurm_${i}_map.out" --dependency=afterok${WAITFOR} \
            --wrap="module load $SINGULARITY
```
### STAR
This section of the pipeline uses STAR (Spliced Transcripts Alignment to a Reference) to perform RNA-Seq read mapping. 
STAR is a fast and accurate aligner for RNA-seq data that performs spliced alignment to a reference genome. 
The mapping step aligns trimmed reads (either single-end or paired-end) to the genome, generating a BAM file sorted by coordinates for downstream analyses.

Input Genome Directory `--genomeDir "$STARgenome"`
+ This points to the indexed reference genome directory.
  The genome index must be pre-built using STAR's indexing tools.
  The `$STARgenome` variable holds the directory path for the specific genome index (e.g., human or mouse).

Read Files `--readFilesIn "$TRIM/${i}_trimmed_F.fq.gz" "$TRIM/${i}_trimmed_R.fq.gz"`
+ Specifies the input trimmed FASTQ files for paired-end sequencing (forward and reverse reads).
  These files are located in the $TRIM directory and are named with the sample identifier ($i).

Compression Command `--readFilesCommand zcat`
+ This instructs STAR to decompress the gzipped input FASTQ files using zcat.

Chimeric Segment Minimum `--chimSegmentMin 15`
+ Specifies the minimum length (in base pairs) for a chimeric segment.
  This option is relevant for detecting chimeric reads, which might represent exon-exon fusions.

Maximum Multimap Reads `--outFilterMultimapNmax 1`
+ Limits the number of allowed alignments (multimapping) for each read.
  Here, only reads that map to exactly one position in the genome are kept.
  This helps reduce ambiguity in the alignment process.

Two-Pass Mode `--twopassMode Basic`
+ Uses a two-pass alignment strategy. In the first pass, STAR aligns the reads to the genome, then identifies exon-exon junctions.
  In the second pass, STAR uses this information to improve read mapping accuracy, particularly for spliced alignments.
+ The Basic mode refers to a simpler version of the two-pass alignment.

Number of Threads `--runThreadN 8`
+ Specifies that STAR should use 8 CPU threads to parallelize the alignment.

Output Format `--outSAMtype BAM SortedByCoordinate`
+ The output format is specified as BAM, sorted by coordinates. This is the standard output format for genomic alignment files.
  It means it is suitable for downstream analyses like variant calling or visualizations in genome browsers (e.g., IGV).

Output Prefix `--outFileNamePrefix "$BAM/${i}_map"`
+ Specifies the prefix for the output files. The result will be saved in the $BAM directory with a prefix matching the sample name.
  The generated files will include:
  + BAM file
  + SA
  + SJ
  These can contain information about spliced alignments and other STAR outputs.

```
if [ "$RUNTYPE" = "PE" ];
         then singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $STAR_SIF STAR \
                   --genomeDir "$STARgenome" \
                   --readFilesCommand zcat \
                   --readFilesIn "$TRIM/${i}_trimmed_F.fq.gz" "$TRIM/${i}_trimmed_R.fq.gz" \
                   --chimSegmentMin 15 \
                   --outFilterMultimapNmax 1 \
                   --twopassMode Basic \
                   --runThreadN 8 \
                   --outSAMtype BAM SortedByCoordinate \
                   --outFileNamePrefix "$BAM/${i}_map"
         else singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $STAR_SIF STAR \
                   --genomeDir "$STARgenome" \
                   --readFilesCommand zcat \
                   --readFilesIn "$TRIM/${i}_trimmed_F.fq.gz" \
                   --chimSegmentMin 15 \
                   --outFilterMultimapNmax 1 \
                   --twopassMode Basic \
                   --runThreadN 8 \
                   --outSAMtype BAM SortedByCoordinate \
                   --outFileNamePrefix "$BAM/${i}_map"
fi
")
```
The JOBID and WAITFOR is important for settign what the dependency for slurm is.

```
      JOBID=`echo $RETVAL | sed "s/Submitted batch job //"`
      WAITFOR2=`echo "${WAITFOR2}:${JOBID}"`
   done
   echo "$WAITFOR2"
```
fi

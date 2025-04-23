#!/bin/bash
###############################################################################################################
#                                                  Stages                                                     #
###############################################################################################################

    SKIPMERGE=
    SKIPQCTRIM=
    SKIP_RNA_MAP=TRUE
    SKIP_DNA_MAP=
    SKIPINDEX=TRUE
    SKIPFC=TRUE
    SKIPSNP=
    SKIPMULTIQC=

    DEBUG=TRUE

###############################################################################################################
#                                                Variables                                                    #
###############################################################################################################

    JobID="VCFcalling"
    TARGET="RNA" #RNA or DNA
    Base="$PWD"
    DataRaw="$Base/Inputs"
    Species="Human"
    CV="gn" #gn ex tx
    MODEL="WGS"
    RUNTYPE="PE"
    SamplesRaw="*R1.fq.gz" #fq.gq | fastq.gz | fastq
    SuffixRawF="*R1.fq.gz"
    SuffixRawR="*R2.fq.gz"
    SuffixRawSE="*.fq.gz"
    SLURM_ACCOUNT="scw####"
    SNPCALLING="Somatic" #Somatic (DeepSomatic) or Germline (DeepVariant)
    SOMATIC_TABLE="Somatic_pairings.txt"
    
################################################################################################################
#                                               Indexes etc                                                    #
################################################################################################################

    STARgenomeH="GRCh38gencodeV39-202201/"
    STARgenomeM="GRCm39gencodev28-202201/"
    BWAgenomeH="GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa"
    BWAgenomeM="GRCm39gencodev28-202201/GRCm39.primary_assembly.genome.fa"
    FASTArefH="GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa"
    FASTArefM="GRCm39gencodev28-202201/GRCm39.primary_assembly.genome.fa"
    GENCODEH="gencode.v39.primary_assembly.annotation.gtf"
    GENCODEM="gencode.vM28.primary_assembly.annotation.gtf"
    BEDH="GRCh38gencodeV39-202201/Illumina_Exome_TargetedRegions_v1.2.hg38.bed"
    BEDM="GRCm39gencodev28-202201/"
    
################################################################################################################
#                                               Containers                                                     #
################################################################################################################
    
    SINGULARITY="singularity/3.8.5"
    SIF_DIR="$Base/SIFS"
    FASTP_SIF="$SIF_DIR/fastp-v0.23.1.sif"
    STAR_SIF="$SIF_DIR/STAR-2.7.9a.sif"
    BWA_SIF="$SIF_DIR/bwa-0.7.17.sif"
    SAMTOOLS_SIF="$SIF_DIR/samtools-1.9.sif"
    DEEPV_SIF="$SIF_DIR/deepvariant_1.3.0.sif"
    DEEPS_SIF="$SIF_DIR/deepsomatic_1.6.0.sif"
    FC_SIF="$SIF_DIR/featurecounts-2.0.3.sif"
    QUALIMAP_SIF="$SIF_DIR/qualimap_v2.2.1.sif"
    BCFTOOLS_SIF="$SIF_DIR/bcftools_v1.10.2.sif"
    PICARD_SIF="$SIF_DIR/picard-2.25.6.sif"
    MULTIQC_SIF="$SIF_DIR/multiqc-v1.11.sif"
    MC_config="$SIF_DIR/multiqc.local.config"
    max_jobs="15"

################################################################################################################
#                                                Defaults                                                      #
################################################################################################################
# Log variables
log_file="${JobID}_log.txt"

# Log selected variables for reference
if [ "$DEBUG" = "TRUE" ]; then
    # If DEBUG is TRUE, log all environment variables using compgen
    echo "$(date '+%F %T') - DEBUG MODE: Logging all environment variables:" >> $log_file
    compgen -v | while read var; do
        echo "$(date '+%F %T') - $var=${!var}" >> $log_file
    done
else
echo "$(date '+%F %T') - Logging key variables:" >> $log_file
echo "$(date '+%F %T') - DEBUG=$DEBUG" >> $log_file
echo "$(date '+%F %T') - SKIPMERGE=$SKIPMERGE" >> $log_file
echo "$(date '+%F %T') - SKIPQCTRIM=$SKIPQCTRIM" >> $log_file
echo "$(date '+%F %T') - SKIP_RNA_MAP=$SKIP_RNA_MAP" >> $log_file
echo "$(date '+%F %T') - SKIP_DNA_MAP=$SKIP_DNA_MAP" >> $log_file
echo "$(date '+%F %T') - SKIPINDEX=$SKIPINDEX" >> $log_file
echo "$(date '+%F %T') - SKIPFC=$SKIPFC" >> $log_file
echo "$(date '+%F %T') - SKIPSNP=$SKIPSNP" >> $log_file
echo "$(date '+%F %T') - SKIPMULTIQC=$SKIPMULTIQC" >> $log_file
echo "$(date '+%F %T') - JobID=$JobID" >> $log_file
echo "$(date '+%F %T') - TARGET=$TARGET" >> $log_file
echo "$(date '+%F %T') - Base=$Base" >> $log_file
echo "$(date '+%F %T') - DataRaw=$DataRaw" >> $log_file
echo "$(date '+%F %T') - Species=$Species" >> $log_file
echo "$(date '+%F %T') - CV=$CV" >> $log_file
echo "$(date '+%F %T') - MODEL=$MODEL" >> $log_file
echo "$(date '+%F %T') - RUNTYPE=$RUNTYPE" >> $log_file
echo "$(date '+%F %T') - SamplesRaw=$SamplesRaw" >> $log_file
echo "$(date '+%F %T') - SuffixRawF=$SuffixRawF" >> $log_file
echo "$(date '+%F %T') - SuffixRawR=$SuffixRawR" >> $log_file
echo "$(date '+%F %T') - SuffixRawSE=$SuffixRawSE" >> $log_file
echo "$(date '+%F %T') - SNPCALLING=$SNPCALLING" >> $log_file
echo "$(date '+%F %T') - SOMATIC_TABLE=$SOMATIC_TABLE" >> $log_file
echo "$(date '+%F %T') - SLURM_ACCOUNT=$SLURM_ACCOUNT" >> $log_file
echo "$(date '+%F %T') - STARgenomeH=$STARgenomeH" >> $log_file
echo "$(date '+%F %T') - STARgenomeM=$STARgenomeM" >> $log_file
echo "$(date '+%F %T') - BWAgenomeH=$BWAgenomeH" >> $log_file
echo "$(date '+%F %T') - BWAgenomeM=$BWAgenomeM" >> $log_file
echo "$(date '+%F %T') - BEDH=$BEDH" >> $log_file
echo "$(date '+%F %T') - BEDM=$BEDM" >> $log_file
echo "$(date '+%F %T') - FASTArefH=$FASTArefH" >> $log_file
echo "$(date '+%F %T') - FASTArefM=$FASTArefM" >> $log_file
echo "$(date '+%F %T') - GENCODEH=$GENCODEH" >> $log_file
echo "$(date '+%F %T') - GENCODEM=$GENCODEM" >> $log_file
echo "$(date '+%F %T') - SINGULARITY=$SINGULARITY" >> $log_file
echo "$(date '+%F %T') - SIF_DIR=$SIF_DIR" >> $log_file
echo "$(date '+%F %T') - FASTP_SIF=$FASTP_SIF" >> $log_file
echo "$(date '+%F %T') - STAR_SIF=$STAR_SIF" >> $log_file
echo "$(date '+%F %T') - BWA_SIF=$BWA_SIF" >> $log_file
echo "$(date '+%F %T') - SAMTOOLS_SIF=$SAMTOOLS_SIF" >> $log_file
echo "$(date '+%F %T') - DEEPV_SIF=$DEEPV_SIF" >> $log_file
echo "$(date '+%F %T') - DEEPV_SIF=$DEEPS_SIF" >> $log_file
echo "$(date '+%F %T') - FC_SIF=$FC_SIF" >> $log_file
echo "$(date '+%F %T') - QUALIMAP_SIF=$QUALIMAP_SIF" >> $log_file
echo "$(date '+%F %T') - BCFTOOLS_SIF=$BCFTOOLS_SIF" >> $log_file
echo "$(date '+%F %T') - MULTIQC_SIF=$MULTIQC_SIF" >> $log_file
echo "$(date '+%F %T') - MC_config=$MC_config" >> $log_file
echo "$(date '+%F %T') - max_jobs=$max_jobs" >> $log_file
fi

# Check targit is RNA or DNA and ensure only one runs
if [ "$TARGET" == "RNA" ]; then
  if [ "$SKIP_DNA_MAP" != "TRUE" ]; then
    echo "$(date '+%F %T') - RNA target selected, skipping DNA mapping." >> $log_file
    exit 0  # Exit if not running RNA-related processes
  fi
elif [ "$TARGET" == "DNA" ]; then
  if [ "$SKIP_RNA_MAP" != "TRUE" ]; then
    echo "$(date '+%F %T') - DNA target selected, skipping RNA processing." >> $log_file
    exit 0  # Exit if not running DNA-related processes
  fi
else
  echo "$(date '+%F %T') - ERROR: Neither RNA nor DNA target selected. Exiting..." >> $log_file
  exit 1  # Error out if neither RNA nor DNA target is set
fi

# Set max jobs function
wait_for_slot() {
  while true; do
    num_jobs=$(squeue -u $USER | wc -l)
    if [ "$num_jobs" -lt "$MAX_JOBS" ]; then
      break
    fi
    echo "$(date '+%F %T') - Waiting for job slot: $num_jobs jobs running/pending..."
    sleep 60
  done
}

# Setup
mkdir -p ${Base}/$JobID/
echo "Created on `date`" >> ${log_file}
mkdir -p $Base/$JobID/logs/trim
mkdir -p $Base/$JobID/logs/bam
mkdir -p $Base/$JobID/logs/VCF
mkdir -p $Base/$JobID/logs/counts
LOGS="$Base/$JobID/logs"
mkdir -p $Base/$JobID/bam
BAM="$Base/$JobID/bam"
mkdir -p $Base/$JobID/trim
TRIM="$Base/$JobID/trim"
mkdir -p $Base/$JobID/tmp
TMP="$Base/$JobID/tmp"
mkdir -p $Base/$JobID/VCF
VCF="$Base/$JobID/VCF"
mkdir -p $Base/$JobID/counts
COUNTS="$Base/$JobID/counts"
echo "$(date '+%F %T') - Made subdirectories" >> $log_file

################################################################################################################
#                                                  Merge                                                       #
################################################################################################################
destination_dir="$Base/$JobID/tmp"
# Check if merging is skipped
if [ "$SKIPMERGE" = "TRUE" ]; then
    echo "$(date '+%F %T') - Linking Files" >> "$log_file"
    if [ "$RUNTYPE" = "SE" ]; then
        for i in $SamplesRaw; do
            dest_file="${destination_dir}/${i}_M_F.fq.gz"
            if [ ! -s "$dest_file" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawSE}" "$dest_file"
            fi
        done
    elif [ "$RUNTYPE" = "PE" ]; then
        for i in $SamplesRaw; do
            dest_file_f="${destination_dir}/${i}_M_F.fq.gz"
            dest_file_r="${destination_dir}/${i}_M_R.fq.gz"
            if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawF}" "$dest_file_f"
                ln -s -f "$DataRaw/${i}*${SuffixRawR}" "$dest_file_r"
            fi
        done
    else
        echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
        exit 1
    fi
else
    # Loop through each sample name
    while IFS= read -r sample_name; do
        dest_file_f="${destination_dir}/${sample_name}_M_F.fq.gz"
        dest_file_r="${destination_dir}/${sample_name}_M_R.fq.gz"
        if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
            if [ "$RUNTYPE" = "SE" ]; then
                files_se=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawSE}")
                if [ -n "$files_se" ]; then
                    for file in $files_se; do
                        cat "$file" >> "$dest_file_f"
                    done
                    echo "$(date '+%F %T') - Merged single-end files for $sample_name" >> "$log_file"
                else
                    echo "$(date '+%F %T') - No single-end files found for $sample_name" >> "$log_file"
                fi
            elif [ "$RUNTYPE" = "PE" ]; then
                files_r1=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawF}")
                files_r2=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawR}")
                if [ -n "$files_r1" ] && [ -n "$files_r2" ]; then
                    for file_r1 in $files_r1; do
                        cat "$file_r1" >> "$dest_file_f"
                        echo "$(date '+%F %T') - Merged R1 files for $sample_name" >> "$log_file"
                    done
                    for file_r2 in $files_r2; do
                        cat "$file_r2" >> "$dest_file_r"
                        echo "$(date '+%F %T') - Merged R2 files for $sample_name" >> "$log_file"
                    done
                else
                    echo "$(date '+%F %T') - No R1 or R2 files found for $sample_name" >> "$log_file"
                fi
            else
                echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
                exit 1
            fi
        else
            echo "$(date '+%F %T') - Skipping merge for $sample_name as destination files already exist and have non-zero size" >> "$log_file"
        fi
    done <<< "$SamplesRaw"
fi


################################################################################################################
#                                                Trimming                                                      #
################################################################################################################
# Submit jobs
WAITFOR=":1"
if [ "$SKIPQCTRIM" = "TRUE" ]; then
    echo "$(date '+%F %T') - Skipping Trimming" >> $log_file
else
    for i in $SamplesRaw; do
       wait_for_slot

      #  while [ $(squeue -u $USER | wc -l) -lt $max_jobs ]; do
      #      sleep 60
      #  done

        echo "$(date '+%F %T') - Starting trimming job ${i}" >> $log_file

        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=2 --time="0-2:00" \
            --error="$LOGS/trim/slurm_${i}_trim.err" --output="$LOGS/trim/slurm_${i}_trim.out" \
            --wrap="module load $SINGULARITY

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

################################################################################################################
#                                               RNA  Mapping                                                   #
################################################################################################################
#Submit jobs
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

        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time="0-6:00" \
            --error="$LOGS/bam/slurm_${i}_map.err" --output="$LOGS/bam/slurm_${i}_map.out" --dependency=afterok${WAITFOR} \
            --wrap="module load $SINGULARITY

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

      JOBID=`echo $RETVAL | sed "s/Submitted batch job //"`
      WAITFOR2=`echo "${WAITFOR2}:${JOBID}"`
   done
   echo "$WAITFOR2"
fi

################################################################################################################
#                                               DNA  Mapping                                                   #
################################################################################################################
#Submit jobs
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
              singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $SAMTOOLS_SIF samtools sort \
                   -@ 8 \
                   -o  "$BAM/${i}.bam" \
                   "$BAM/${i}.sam"

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

################################################################################################################
#                                                 Indexing                                                     #
################################################################################################################
#Submit jobs
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

        RETVAL=$(sbatch \
            --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=2 --time=0-1:00 \
            --error="$LOGS/bam/slurm_${i}_index.err" --output="$LOGS/bam/slurm_${i}_index.out" --dependency=afterok${WAITFOR2} \
            --wrap="module load $SINGULARITY

        # Check for dedup BAM and index it
        if [ -f "$BAM/${i}_dedup.bam" ]; then
            echo "Indexing deduplicated BAM: ${i}_dedup.bam"
            singularity exec --bind "$Base/:$Base/" --bind "$SIF_DIR/:$SIF_DIR/" "$SAMTOOLS_SIF" \
                samtools index -@ 2 "$BAM/${i}_dedup.bam"

            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $QUALIMAP_SIF qualimap bamqc \
                -bam "$BAM/${i}_dedup.bam" -gff "${Base}/${STARgenome}${GENCODE}" -outdir $LOGS/bam/${i}_qualimap
        fi

        # Check for sorted-by-coords BAM and index it
        if [ -f "$BAM/${i}_mapAligned.sortedByCoord.out.bam" ]; then
            echo "Indexing sorted BAM: ${i}_mapAligned.sortedByCoord.out.bam"
            singularity exec --bind "$Base/:$Base/" --bind "$SIF_DIR/:$SIF_DIR/" "$SAMTOOLS_SIF" \
                samtools index -@ 2 "$BAM/${i}_mapAligned.sortedByCoord.out.bam"

            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $QUALIMAP_SIF qualimap bamqc \
                -bam "$BAM/${i}_mapAligned.sortedByCoord.out.bam" -gff "${Base}/${STARgenome}${GENCODE}" -outdir $LOGS/bam/${i}_qualimap
        fi

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

################################################################################################################
#                                              Feature Counts                                                  #
################################################################################################################
#Submit jobs
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
fi

################################################################################################################
#                                               SNP Calling                                                    #
################################################################################################################
# run Google Deep variant
WAITFOR4="$WAITFOR4:1"

if [ "$SKIPSNP" = "TRUE" ]; then
  echo "$(date '+%F %T') - Skipping Variant calling" >> "$log_file"

else 
  if [ "$SNPCALLING" = "Somatic" ]; then
    echo "$(date '+%F %T') - Starting Somatic Variant calling" >> "$log_file"

    if [ "$Species" = "Human" ]; then
      FASTAref="$FASTArefH"
    else
      FASTAref="$FASTArefM"
    fi

    while IFS= read -r line; do
      wait_for_slot
      sample=$(echo "$line" | awk '{print $1}')
      matched_sample=$(echo "$line" | awk '{print $2}')

      echo "$(date '+%F %T') - Running somatic process with tumor: $sample, normal: $matched_sample" >> "$log_file"

      vcf_file="$VCF/${sample}_somatic_variants.vcf.gz"
      stats_file="$LOGS/VCF/${sample}_tumor.stats"

      if [ ! -f "$vcf_file" ]; then
        RETVAL=$(sbatch \
          --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time=0-8:00 \
          --error="$LOGS/VCF/slurm_${sample}_index.err" --output="$LOGS/VCF/slurm_${sample}_index.out" \
          --dependency=afterok${WAITFOR3} \
          --wrap="module load $SINGULARITY

            mkdir -p $TMP/${sample}_somatic

            singularity exec $DEEPS_SIF run_deepsomatic \
              --model_type=$MODEL \
              --ref=$FASTAref \
              --reads_normal=$BAM/${matched_sample}.bam \
              --reads_tumor=$BAM/${sample}.bam \
              --output_vcf=$VCF/${sample}_somatic_variants.vcf.gz \
              --output_gvcf=$VCF/${sample}_somatic_variants.g.vcf.gz \
              --num_shards=8 \
              --intermediate_results_dir=$TMP/${sample}_somatic \
              --sample_name_normal=${matched_sample}_normal \
              --sample_name_tumor=${sample}_tumor

            singularity exec $BCFTOOLS_SIF bcftools stats \
              $VCF/${sample}_somatic_variants.vcf.gz > $LOGS/VCF/${sample}_tumor.stats
          ")

        JOBID=$(echo "$RETVAL" | sed "s/Submitted batch job //")
        WAITFOR4="${WAITFOR4}:${JOBID}"

      else
        echo "$(date '+%F %T') - Skipping $sample: VCF already exists at $vcf_file" >> "$log_file"
      fi

    done < "$SOMATIC_TABLE"

  else
    for i in $SamplesRaw; do
        wait_for_slot
        echo "$(date '+%F %T') - Starting Germline Variant calling job ${i}" >> "$log_file"

      if [ "$Species" = "Human" ]; then
        FASTAref="$FASTArefH"
      else
        FASTAref="$FASTArefM"
      fi
      
      if [ ! -f "$vcf_file" ]; then
      RETVAL=$(sbatch \
        --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time=0-8:00 \
        --error="$LOGS/VCF/slurm_${i}_index.err" --output="$LOGS/VCF/slurm_${i}_index.out" \
        --dependency=afterok${WAITFOR3} \
        --wrap="module load $SINGULARITY

          mkdir -p $TMP/${i}

          singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $DEEPV_SIF run_deepvariant \
            --model_type=$MODEL \
            --ref=$FASTAref \
            --reads=$BAM/${i}.bam \
            --output_vcf=$VCF/${i}_variants.vcf.gz \
            --output_gvcf=$VCF/${i}_variants.g.vcf.gz \
            --num_shards=8 \
            --intermediate_results_dir=$TMP/${i} \
            --sample_name=${i}

          singularity exec $BCFTOOLS_SIF bcftools stats \
            $VCF/${i}_variants.vcf.gz > $LOGS/VCF/${i}.stats
        ")

      JOBID=$(echo "$RETVAL" | sed "s/Submitted batch job //")
      WAITFOR4="${WAITFOR4}:${JOBID}"
      else
        echo "$(date '+%F %T') - Skipping $sample: VCF already exists at $vcf_file" >> "$log_file"
      fi
    done
  fi
fi

echo "$WAITFOR4"


################################################################################################################
#                                                  Stats                                                       #
################################################################################################################
# run multiqc
if [ "$SKIPMULTIQC" = "TRUE" ];
  then echo "$(date '+%F %T') - Skipping MultiQC" >> $log_file
  else wait_for_slot
       sbatch --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=1 --time=0-0:10 \
              --error="$LOGS/slurm_QC.err" --output="$LOGS/slurm_QC.out" --dependency=afterok${WAITFOR4} \
              --wrap="module load $SINGULARITY
                      echo "Starting MultiQC" >> $log_file
                      singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $MULTIQC_SIF multiqc \
                                       -f $LOGS \
                                       -o $LOGS/ \
                                       --config $MC_config"
fi

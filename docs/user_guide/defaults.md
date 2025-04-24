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

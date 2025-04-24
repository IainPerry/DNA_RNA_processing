# Stages

    SKIPMERGE=
    SKIPQCTRIM=
    SKIP_RNA_MAP=TRUE
    SKIP_DNA_MAP=
    SKIPINDEX=TRUE
    SKIPFC=TRUE
    SKIPSNP=
    SKIPMULTIQC=

    DEBUG=TRUE

# Variables

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
    
# Indexes

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
    
# Containers 
    
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

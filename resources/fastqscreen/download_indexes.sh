#!/bin/bash

BASE_DIR="$PWD"

# Bwa indexer (make sure it's in your PATH)
    SINGULARITY="singularity/3.8.5"
    SIF_DIR="$Base/SIFS"
    BCL2FASTQ_SIF="$SIF_DIR/bcl2fastq2-v2-20-0.sif"
    BWA="bwa-0.7.17.sif"

download_and_index_bwa () {
    NAME=$1
    URL=$2
    OUTDIR=$3
    FASTA_NAME=$4

    echo "Processing $NAME..."

    mkdir -p "$OUTDIR"
    cd "$OUTDIR" || exit

    if [ ! -f "$FASTA_NAME" ]; then
        echo "Downloading $NAME..."
        wget -O "${FASTA_NAME}.gz" "$URL"
        gunzip "${FASTA_NAME}.gz"
    fi

    echo "Indexing $NAME with BWA inside Singularity..."
    module load "$SINGULARITY"
    singularity exec --bind "$BASE_DIR":"$BASE_DIR" --bind "$SIF_DIR":"$SIF_DIR" "$BWA" \
        bwa index "$FASTA_NAME"
}

# ---- Download and Index Genomes ----

download_and_index_bwa "Human" \
    ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz \
    "$BASE_DIR/Human" \
    Homo_sapiens.GRCh38.fa

download_and_index_bwa "Mouse" \
    ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz \
    "$BASE_DIR/Mouse" \
    Mus_musculus.GRCm38.fa

download_and_index_bwa "Rat" \
    ftp://ftp.ensembl.org/pub/current_fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz \
    "$BASE_DIR/Rat" \
    Rnor_6.0.fa

download_and_index_bwa "Drosophila" \
    ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/dna/Drosophila_melanogaster.BDGP6.dna.toplevel.fa.gz \
    "$BASE_DIR/Drosophila" \
    BDGP6.fa

download_and_index_bwa "Worm" \
    ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/dna/Caenorhabditis_elegans.WBcel235.dna.toplevel.fa.gz \
    "$BASE_DIR/Worm" \
    Caenorhabditis_elegans.WBcel235.fa

download_and_index_bwa "Yeast" \
    ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz \
    "$BASE_DIR/Yeast" \
    Saccharomyces_cerevisiae.R64-1-1.fa

download_and_index_bwa "Arabidopsis" \
    ftp://ftp.ensembl.org/pub/current_fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz \
    "$BASE_DIR/Arabidopsis" \
    Arabidopsis_thaliana.TAIR10.fa

download_and_index_bwa "Ecoli" \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz \
    "$BASE_DIR/E_coli" \
    Ecoli.fa

download_and_index_bwa "PhiX" \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/819/615/GCF_000819615.1_ViralProj15003/GCF_000819615.1_ViralProj15003_genomic.fna.gz \
    "$BASE_DIR/PhiX" \
    phi_plus_SNPs.fa

download_and_index_bwa "Lambda" \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/840/245/GCF_000840245.1_ViralProj13955/GCF_000840245.1_ViralProj13955_genomic.fna.gz \
    "$BASE_DIR/Lambda" \
    Lambda.fa

download_and_index_bwa "rRNA-Mouse" \
    ftp://ftp.ensembl.org/pub/release-108/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz \ 
    "$BASE_DIR/rRNA" 
    GRCm38_rRNA.fa

download_and_index_bwa "Mitochondria-Mouse" \
    https://www.ncbi.nlm.nih.gov/search/api/sequence/NC_005089.1/?report=fasta&format=text \
    "$BASE_DIR/Mitochondria" 
    mitochondria.fa

download_and_index_bwa "Vectors-UniVec" \
    ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec
    "$BASE_DIR/Vectors" 
    UniVec.fa

download_and_index_bwa "Vectors-UniVec_Core" \
    ftp://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec_Core \
    "$BASE_DIR/Vectors" 
    UniVec_Core.fa

echo "All available references downloaded and indexed with BWA."

# Resources
As part of a list of resources provided here, i include details for fastq screen. This is part of the BCL2FASQ.sh

## fastq screen
"FastQ Screen allows you to screen a library of sequences in FastQ format against a set of sequence databases so you can see if the composition of the library matches with what you expect."
[Fastq screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/) is used here to look for contamination

### download_indexes.sh
First set options:
```
    SINGULARITY="singularity/3.8.5"
    SIF_DIR="$Base/SIFS"
    BCL2FASTQ_SIF="$SIF_DIR/bcl2fastq2-v2-20-0.sif"
    BWA="bwa-0.7.17.sif"
```
Then set a function to download and install using bwa.
This ideally should be modified to sbatch as bwa is an intensive process.
```
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
```
Example of the first genome to download
```
# ---- Download and Index Genomes ----

download_and_index_bwa "Human" \
    ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz \
    "$BASE_DIR/Human" \
    Homo_sapiens.GRCh38.fa
```

### fastq_screen.conf
This is just the configuration file explaining where fastq screen should look for indexed genomes.

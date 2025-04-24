# Stages

##SKIPS
These variables control which stages of the pipeline are skipped. Setting a flag to TRUE will bypass that stage. Useful for restarting partial runs, testing modules in isolation, or tailoring to specific datasets (e.g. RNA-only, DNA-only).

### SKIPMERGE
Often when runs come off a sequencer, they will come in several lanes. There is some debate on where you should do the merging. Some do it as the first step as we are doing here, some after mapping. Historically the reason was because lanes could cause artifacts that impacted duplication levels. Generally speaking seqeuencers are now no longer have those problems and duplication can be removed later on.

### SKIPQCTRIM
Skips initial quality control and adapter trimming using Fastp. Use this if your reads have already been cleaned or you're troubleshooting downstream steps. Note that skipping this may lead to worse mapping performance or inflated duplication rates.

### SKIP_RNA_MAP
Skips RNA mapping with STAR. If you’re only interested in DNA processing or already have STAR-aligned BAMs, enable this. Also useful for workflows that separate DNA and RNA into different scripts.

### SKIP_DNA_MAP
Skips DNA mapping with BWA. If RNA is your only target or you’ve already generated BWA BAMs for DNA samples, skip this to save time.

### SKIPINDEX
Skips indexing of BAM files. Normally, indexing is required for downstream steps like variant calling or visualization. This option exists to save compute time if those steps aren’t needed.

### SKIPFC
Skips FeatureCounts. Use this if expression quantification is not needed (e.g., for pure variant calling pipelines). Note: this will also affect downstream multiQC if you include its results.

### SKIPSNP
Skips variant calling using DeepSomatic or DeepVariant, depending on your SNPCALLING mode. Ideal if you've already run variant calling and just want to rerun other steps (e.g., QC or featurecounts).

### SKIPMULTIQC
Skips final aggregation of QC reports using MultiQC. Useful when debugging earlier steps and you don’t need a final summary yet. You can always rerun MultiQC standalone with the same config later.

### DEBUG
If DEBUG is TRUE, log all environment variables using compgen. This means loads of extra user and system information.

## Variables
These variables define the core configuration of your run — including sample data, species, runtime behavior, and execution environment.

### JobID
A label for the current job or workflow run. Used to prefix output files and job names, particularly useful in SLURM or log tracking.
Example: ***VCFcalling***

### TARGET
Specifies whether the analysis targets RNA or DNA. This flag controls which mapping and downstream logic gets executed.
Options: `RNA` & `DNA`

### Base
Base directory path - typically you'll set as the current working directory using `$PWD`. All paths are relative to this.
Optionally you can hard specify, example: `/your/path/to/project`

### DataRaw
Path to the folder containing raw input FASTQ files. You may wish to hard specify a new location or build it in from you now defined Base.
Example: `$Base/Inputs`

### Species
Currently this script is only set to work with `Human` or `Mouse`, and it allows quickly to select from your defined variables below. But in theory theres no reason you couldnt swap mouse to rat for example.

### CV=
Code used to select transcript annotations or capture kits.
Examples:
+ `gn` – Gene-level
+ `ex` – Exon-level
+ `tc` – Transcript-level

### MODEL
Sequencing model or data type. Controls which BED/FASTA files are selected for deepsomatic and deepvariant.
Example: `WGS` (Whole Genome), `WES` (Whole Exome), etc.

### RUNTYPE
Indicates whether the data is paired-end or single-end.
Options: `PE`, `SE`

### SamplesRaw
You can supply a list within the script itself, for example:
```
SamplesRaw="Sample1
Sample2
Sample3"
```
but its probably easier and cleaner to supply a list of samples, for example: 
```$(<samples_names.txt)```

### SuffixRawF and SuffixRawR
Suffix pattern for forward and reverse reads. Used when trimming or mapping paired-end data.
Example: `"*R1.fq.gz"` and `"*R2.fq.gz"` or `"*R1.fastq.gz"` `"*R2.fastq.gz"`

### SuffixRawSE=
Like SuffixRawF and SuffixRawR.
Example: `"*R1.fq.gz"` or `"*.fq.gz"`

### SLURM_ACCOUNT
A slurm account can be taken by default if you're only part of one account, but you may wish to specify.
Example: `scw0001`

### SNPCALLING
Controls which variant calling method is used.
Options:
+ `Somatic` (runs DeepSomatic)
+ `Germline` (runs DeepVariant)
  
### SOMATIC_TABLE=
File containing tumour-normal pairings (if using somatic calling). Should be a TSV with at least two columns: Tumour\Normal.
e.g. 
```
Patient1_tumour1    Patient1_normal1
Patient1_tumour2    Patient1_normal2
Patient1_tumour3    Patient1_normal3
```
Specify this file like this: `"Somatic_pairings.txt"`
    
## Indexes
These define paths to reference genomes, annotations, and target regions for mapping and variant calling. Make sure the correct species-specific and analysis-type-specific files are selected.

### STARgenomeH
Path to the Human STAR genome index directory, prebuilt for your annotation version (e.g., Gencode v39).
Example: `GRCh38gencodeV39-202201/`

### STARgenomeM
Path to the Mouse STAR genome index directory.
Example: `GRCm39gencodev28-202201/`

### BWAgenomeH
FASTA reference genome for Human, used by BWA for alignment. BWA like the fasta specifically identified unlike STAR which makes do with just the directory.
Example: `GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa`

### BWAgenomeM
FASTA reference genome for Mouse, used by BWA.
Example: `GRCm39gencodev28-202201/GRCm39.primary_assembly.genome.fa`

### FASTArefH
Reference FASTA file for Human, used in variant calling and downstream tools.
Same as: either specify as in BWAgenomeH, or link to that preset variable.
Example: `GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa` or `$BWAgenomeH`

### FASTArefM
Reference FASTA file for Mouse, used in variant calling.
Same as: BWAgenomeM

### GENCODEH
Gene annotation GTF file for Human, typically from Gencode.
Example: `gencode.v39.primary_assembly.annotation.gtf`

### GENCODEM
Gene annotation GTF file for Mouse.
Example: `gencode.vM28.primary_assembly.annotation.gtf`

### BEDH
Target regions BED file for Human, usually provided by capture kit vendor or Illumina.
Example: `GRCh38gencodeV39-202201/Illumina_Exome_TargetedRegions_v1.2.hg38.bed`

### BEDM
Target regions BED file for Mouse.
Example: `GRCm39gencodev28-202201/example.bed`
    
## Containers 
The below section really is about telling the script where your containers are stored.
    
### SINGULARITY
I've most recently been using `singularity/3.8.5`. You'll need to load as a module or have it run as part of your path.

### SIF_DIR
Where you store all you containers.
Example: `"$Base/SIFS"`

### Containers
Below is the containers and version currently included as def files to build, but you can set/build your own
```
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
```
### MC_config
If you want to have a more bespoke MultiQC report you'll want to set one of these up:
`"$SIF_DIR/multiqc.local.config"`

### max_jobs
Some slurm clusters will have a max number of jobs you can submit at any given time. This helps to moderate and slow the script so jobs are not rejected. It is the area where Nextflow becomes more powerful.
Example: `"15"`

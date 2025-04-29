# DNA_RNA_processing with Nextflow
This guide aims to suggest how to run the main script as a nextflow pipeline from scratch.
No prior knowledge of nextflow should be necessary but several steps can be skipped with experience.
+ Install nextflow
+ Nextflow directory structure


### Prerequisites
+ It is highly advised a medium to high level of linux command line knowledge


## Setup Nextflow 
1. First install nextflow:
   `curl -s https://get.nextflow.io | bash`
   `mv nextflow ~/bin/  # or anywhere in PATH`
2. Install Singularity if not already available:
   `sudo apt install singularity-container`
3. Check install and versions:
   `nextflow -v `
   `singularity --version`

## Directory layout
Nextflow directory structure can get very confusing, very quickly, particually when jobs run.
Initially you'll set up a clean pipeline like below:
```
my_pipeline/
├── main.nf
├── nextflow.config
├── params.json
├── bin/
│   └── trim.nf          
│   └── rna_map.nf    
│   └── dna_map.nf    
│   └── index.nf  
│   └── featcount.nf        
│   └── variant.nf  
├── data/
│   ├── sample1_M_F.fq.gz
│   └── sample1_M_R.fq.gz
└── results/
```

Nextflow is very obscure with directory structure. for example you may see directories generated that look like this:

```
├── 00/
│   └── 0056da34a7b45ebb41f95f9e88bad9
│   └── 2e899c62b8939c59c83dc5235e8876   
```

## Config file
Setting your nextflow.config file is the first step. Nexflow uses a version of java called ***groovy***
Rather than set the job requirements in the script, we define them here.

```
// Global settings
process {
    executor = 'slurm'  
    queue    = 'default'
    maxRetries = 2
    errorStrategy = 'retry'
```

We can define resources for each step
+ We first define the nextflow process name
+ We then define number of cpus to use
+ We define memory to allocate
+ We give a timelimit for each job
+ We define which cluster to use.
+ You may only have access to one queue, but HPC often has different queues for smaller and larger jobs
    
```
    withName: '*Trim*' {
        cpus = 2
        memory = '4 GB'
        time = '2h'
        queue = 'small'   
    }
    withName: '*RnaMap*' {
        cpus = 8
        memory = '32 GB'
        time = '8h'
        queue = 'large'
    }
    withName: '*DnaMap*' {
        cpus = 16
        memory = '64 GB'
        time = '12h'
        queue = 'large'
    }
    withName: '*Index*' {
        cpus = 4
        memory = '8 GB'
        time = '2h'
        queue = 'small'  
    }
    withName: '*Featcount*' {
        cpus = 4
        memory = '16 GB'
        time = '2h'
        queue = 'small'  
    }
    withName: '*Variant*' {
        cpus = 8
        memory = '32 GB'
        time = '6h'
        queue = 'large'
    }
}

```

Some places have docker instead of singularity, but we dont have that

```
// Define profiles for local vs SLURM
profiles {
    local {
        process.executor = 'local'
        docker.enabled = false
    }

    slurm {
        process.executor = 'slurm'
        singularity.enabled = true
        singularity.autoMounts = true
        singularity.runOptions = '--cleanenv'
    }
}

// Custom parameters usable in any script
params {
    input_dir = 'data'
    output_dir = 'results'

    sif_dir    = '/path/to/sifs'
    trim_sif   = "${params.sif_dir}/fastp_latest.sif"
    map_sif    = "${params.sif_dir}/star_latest.sif"
    count_sif  = "${params.sif_dir}/subread_latest.sif"
    var_sif    = "${params.sif_dir}/gatk_latest.sif"

    run_type = 'PE'  // or SE for single-end
    slurm_account = 'my_account_name'
}

```

You'll notice above, we set the sif vairables here too. These can and should be overridden when submitting jobs, but they function as defaults.
You can over ride like this:

```
nextflow run main.nf -profile slurm \
  --input_dir 'raw_data' \
  --output_dir 'analysis_output' \
  --sif_dir '/efs/singularity_images' \
  --run_type 'SE' \
  --slurm_account 'bioinf_team'
```

or preferably with your variables in a .json which is mostly the same as our previous script.

`nextflow run main.nf -profile slurm -params-file job_params.json`

and

```
{
  "SKIPMERGE": "",
  "SKIPQCTRIM": "",
  "SKIP_RNA_MAP": "TRUE",
  "SKIP_DNA_MAP": "",
  "SKIPINDEX": "TRUE",
  "SKIPFC": "TRUE",
  "SKIPSNP": "",
  "SKIPMULTIQC": "",

  "DEBUG": "TRUE",
  "JobID": "VCFcalling",
  "TARGET": "RNA",
  "Base": "/absolute/path/to/project",
  "DataRaw": "/absolute/path/to/project/Inputs",
  "Species": "Human",
  "CV": "gn",
  "MODEL": "WGS",
  "RUNTYPE": "PE",
  "SamplesRaw": "sample1 sample2 sample3",

  "SuffixRawF": "*R1.fq.gz",
  "SuffixRawR": "*R2.fq.gz",
  "SuffixRawSE": "*.fq.gz",
  "SLURM_ACCOUNT": "scw####",
  "SNPCALLING": "Somatic",
  "SOMATIC_TABLE": "Somatic_pairings.txt",

  "STARgenomeH": "GRCh38gencodeV39-202201/",
  "STARgenomeM": "GRCm39gencodev28-202201/",
  "BWAgenomeH": "GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa",
  "BWAgenomeM": "GRCm39gencodev28-202201/GRCm39.primary_assembly.genome.fa",
  "FASTArefH": "GRCh38gencodeV39-202201/GRCh38.primary_assembly.genome.fa",
  "FASTArefM": "GRCm39gencodev28-202201/GRCm39.primary_assembly.genome.fa",
  "GENCODEH": "gencode.v39.primary_assembly.annotation.gtf",
  "GENCODEM": "gencode.vM28.primary_assembly.annotation.gtf",
  "BEDH": "GRCh38gencodeV39-202201/Illumina_Exome_TargetedRegions_v1.2.hg38.bed",
  "BEDM": "GRCm39gencodev28-202201/",

  "SINGULARITY": "singularity/3.8.5",
  "SIF_DIR": "/absolute/path/to/project/SIFS",
  "FASTP_SIF": "/absolute/path/to/project/SIFS/fastp-v0.23.1.sif",
  "STAR_SIF": "/absolute/path/to/project/SIFS/STAR-2.7.9a.sif",
  "BWA_SIF": "/absolute/path/to/project/SIFS/bwa-0.7.17.sif",
  "SAMTOOLS_SIF": "/absolute/path/to/project/SIFS/samtools-1.9.sif",
  "DEEPV_SIF": "/absolute/path/to/project/SIFS/deepvariant_1.3.0.sif",
  "DEEPS_SIF": "/absolute/path/to/project/SIFS/deepsomatic_1.6.0.sif",
  "FC_SIF": "/absolute/path/to/project/SIFS/featurecounts-2.0.3.sif",
  "QUALIMAP_SIF": "/absolute/path/to/project/SIFS/qualimap_v2.2.1.sif",
  "BCFTOOLS_SIF": "/absolute/path/to/project/SIFS/bcftools_v1.10.2.sif",
  "PICARD_SIF": "/absolute/path/to/project/SIFS/picard-2.25.6.sif",
  "MULTIQC_SIF": "/absolute/path/to/project/SIFS/multiqc-v1.11.sif",
  "MC_config": "/absolute/path/to/project/SIFS/multiqc.local.config"
}

```

## main.nf
This is what controls the main running of the script. The setting up and merging of files is such a low cpu job, we can run it on the head node.
So we can include it here.

```
// main.nf

// Import each module script
include { TRIM } from './bin/trim.nf'
include { RNA_MAP } from './bin/rna_map.nf'
include { DNA_MAP } from './bin/dna_map.nf'
include { INDEX } from './bin/index.nf'
include { FEATCOUNT } from './bin/featcount.nf'
include { VARIANT } from './bin/variant.nf'

// Initialize log
log_file = "${params.base}/${params.job_id}/pipeline.log"

workflow {
    // Project Setup
    def base = file(params.base)
    def jobid = params.job_id
    def logs = "${base}/${jobid}/logs"
    def dirs = [
        "${base}/${jobid}",
        "${logs}/trim",
        "${logs}/bam",
        "${logs}/VCF",
        "${logs}/counts",
        "${base}/${jobid}/bam",
        "${base}/${jobid}/trim",
        "${base}/${jobid}/tmp",
        "${base}/${jobid}/VCF",
        "${base}/${jobid}/counts"
    ]

    dirs.each { dir ->
        file(dir).mkdirs()
    }
    log.info "Directories created"

    // Merge Setup
    def tmpDir = file("${base}/${jobid}/tmp")
    def samplesRaw = params.samples_raw.split("\n")

    if (params.skip_merge == true) {
        log.info "Linking files (SKIPMERGE=TRUE)"
        samplesRaw.each { i ->
            if (params.runtype == "SE") {
                def dest = tmpDir.resolve("${i}_M_F.fq.gz")
                if (!dest.exists()) {
                    def src = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_se) }
                    dest.createLink(src)
                }
            } else {
                def destF = tmpDir.resolve("${i}_M_F.fq.gz")
                def destR = tmpDir.resolve("${i}_M_R.fq.gz")
                if (!destF.exists()) {
                    def srcF = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_f) }
                    destF.createLink(srcF)
                }
                if (!destR.exists()) {
                    def srcR = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_r) }
                    destR.createLink(srcR)
                }
            }
        }
    } else {
        log.info "Merging files (SKIPMERGE=FALSE)"
        samplesRaw.each { sample ->
            if (params.runtype == "SE") {
                def dest = tmpDir.resolve("${sample}_M_F.fq.gz")
                if (!dest.exists()) {
                    def srcs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_se) }
                    def merged = dest.newOutputStream()
                    srcs.each { file -> file.eachLine { merged << it + '\n' } }
                    merged.close()
                }
            } else {
                def destF = tmpDir.resolve("${sample}_M_F.fq.gz")
                def destR = tmpDir.resolve("${sample}_M_R.fq.gz")
                if (!destF.exists() || !destR.exists()) {
                    def srcFs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_f) }
                    def srcRs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_r) }
                    def outF = destF.newOutputStream()
                    def outR = destR.newOutputStream()
                    srcFs.each { file -> file.eachLine { outF << it + '\n' } }
                    srcRs.each { file -> file.eachLine { outR << it + '\n' } }
                    outF.close()
                    outR.close()
                }
            }
        }
    }

```

We then set up the optional modules to run.

```
    // Conditional step execution
    if (!params.skipqctrim) {
        TRIM()
    }
    if (!params.skip_rna_map) {
        RNA_MAP()
    }
    if (!params.skip_dna_map) {
        DNA_MAP()
    }
    if (!params.skipindex) {
        INDEX()
    }
    if (!params.skipfc) {
        FEATCOUNT()
    }
    if (!params.skipsnp) {
        VARIANT()
    }
}

```

## Example module for trim
We also need to run our modules. Here is an example of running the trimming stage.
Java runs a diffent approach of inputs and outputs, so we need to define them all athe beginning before the actual command is run below

```
process trim_reads {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads_fq1), path(reads_fq2)

    output:
    tuple val(sample_id), path("${sample_id}_trimmed_F.fq.gz"), path("${sample_id}_trimmed_R.fq.gz")

    script:
    def out_html = "${params.Base}/${params.JobID}/logs/trim/${sample_id}_fastp.html"
    def out_json = "${params.Base}/${params.JobID}/logs/trim/${sample_id}_fastp.json"

    """
    singularity exec --bind ${params.Base}:${params.Base} --bind ${params.SIF_DIR}:${params.SIF_DIR} ${params.FASTP_SIF} fastp \
        --in1 $reads_fq1 \
        --in2 $reads_fq2 \
        --out1 ${sample_id}_trimmed_F.fq.gz \
        --out2 ${sample_id}_trimmed_R.fq.gz \
        --thread 2 \
        -h ${out_html} \
        -j ${out_json}
    """
}

```

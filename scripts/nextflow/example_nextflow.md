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
    withName: '*Trim*' {
        cpus = 2
        memory = '4 GB'
        time = '1h'
        queue = 'short' 
    }
    withName: '*RnaMap*' {
        cpus = 8
        memory = '32 GB'
        time = '8h'
        queue = 'rna'
    }

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
or prefereably with your variables in a .json `nextflow run main.nf -profile slurm -params-file job_params.json`
```
{
  "input_dir": "project1/data",
  "output_dir": "project1/output",
  "sif_dir": "/containers/sifs",
  "run_type": "PE",
  "slurm_account": "team_genomics"
}
```
## main.nf
This is what controls the main running of the script see the example script for main.nf in this directory

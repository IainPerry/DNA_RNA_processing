# BCL2Fastq
This is an example of a script you may run to generate your initial fastq files from raw sequencing outputs. 
The below example is set to run as a stand alone script which could be triggered by a cron job or on successful complettion of a sequencing run.

## Setup
First we define the SLURM requirements
```
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=20
#SBATCH --cpus-per-task=1
##SBATCH --mem=360000
#SBATCH --error=%J.err
#SBATCH --output=%J.out
```
## Vairables
Then we define variables. Below are some examples, but you could set this up to run as a executable in your local bin, filling in from sample sheets for example.
```
    JobID="VCFcalling"
    Base="$PWD"
    RUNFILE="230315_A00123_0456_BHCKFLDRX3"

    DataRaw="$Base/$RUNFILE"
    FQDIR="$Base/Inputs"
    SAMPLES=SampleSheet   # SampleSheet (no .csv on end)

    SINGULARITY="singularity/3.8.5"
    SIF_DIR="$Base/SIFS"
    BCL2FASTQ_SIF="$SIF_DIR/bcl2fastq2-v2-20-0.sif"
    FASTQC_SIF="fastqc_v0.11.9.sif"
    FASTQ_SCREEN_SIF="fastq_screen-0.14.1.sif"
    MULTIQC_SIF="$SIF_DIR/multiqc-v1.11.sif"
    MC_config="$SIF_DIR/multiqc.local.config"
    INTEROP_SIF="interop-v1.1.23.sif"
```
## Demux
The first stage will be loading singularity and then running bcl2fastq.
This converts raw sequencing data into fastq files. You may have your own preferences on exact methods of demux, but here is an example.

```
    module load $SINGULARITY
       
    singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $BCL2FASTQ_SIF  bcl2fastq -p 20 
                                                                                    --runfolder-dir ${DataRaw} \
                                                                                    --output-dir ${FQDIR} \
                                                                                    --sample-sheet  ${DataRaw}/${SAMPLES}.csv  \
                                                                                    --ignore-missing-bcls #\
										                                                               #--no-lane-splitting
```
## QC
Then we move onto QC
Below is an example of another way of parrelising jobs inside a single slurm script.
The main downside is as they all run together as the same job, log messages can get a bit jumbled from each output.


### The first step sets up the first function
```
open_sem(){
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for((;i>0;i--)); do
        printf %s 000 >&3
    done
}
```
### Run the given command asynchronously and pop/push tokens
```
run_with_lock(){
    local x
```    
### This read waits until there is something to read
```
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
     ( "$@"; )
```
### Push the return code of the command to the semaphore
```
    printf '%.3d' $? >&3
    )&
}
```
### Finally set the number of jobs that can run simultaniously 
```
N=3
```
### Run the QC setup
```
open_sem $N

mkdir -p $Base/$JobID/logs/DEMUX
LOGS="$Base/$JobID/logs"
```
### Run fastqc
Fastqc is run here, but fastp could work too
```
mkdir -p $Base/$JobID/logs/DEMUX/FastQC
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTQC_SIF fastqc -t 20 ${FQDIR}/*.fastq.gz --outdir ${LOGS}/FastQC
```
### Run fastq_screen
A quick way to look for contamination. You'll need to set up the genome indexes (shown in resources/fastqscreen).
It will subsample your reads looking to map reads dirtly. Ideally if you're looking at human, most reads will map there.
You will see some overlap with other species due to natual genetic similarity, but it hopefully spots bigger issues like * *microplasmodium* *
```
mkdir -p $Base/$JobID/logs/DEMUX/Fastqscreen
for i in $(cd ${FQDIR}/ && find . -name "*.fastq.gz"); do
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTQ_SCREEN_SIF fastq_screen --conf resources/fastqscreen/fastq_screen.conf ${FQDIR}/${i} --outdir ${LOGS}/Fastqscreen --subset 50000
done
```

### Run interop
A lab tool exists for this, but we can similarly run it here. It gives us useful information on the sequencers run. e.g. lane biases

```
mkdir -p $Base/$JobID/logs/DEMUX/interop
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF summary --csv=1 $DataRaw > $LOGS/DEMUX/interop/interop_summary.csv
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF summary --csv=1 $DataRaw > $LOGS/DEMUX/interop/interop_index-summary.csv
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_qscore_heatmap $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_qscore_heatmap.png
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_qscore_histogram $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_qscore_histogram.png
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_by_lane $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_by_lane.png
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_by_cycle $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_by_cycle.png
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_by_flowcell $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_by_flowcell.png
singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $INTEROP_SIF plot_flowcell $DataRaw | gnuplot > $LOGS/DEMUX/interop/plot_flowcell.png

montage $LOGS/DEMUX/interop/*.png -mode Concatenate -frame 5 -tile 2x4 $LOGS/DEMUX/interop/InterOp_mqc.png
```

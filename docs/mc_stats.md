# Stats
### MultiQC
Our simplest step is running multiqc. This grabs all of our log files and stats and formats them into a nice clean dynamic html file.
+ We need to define what the input files are. We stored them in our LOGS directory.
+ We define where we output our report
+ We give a configuration file, that helps with how the report file looks!
```
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
```

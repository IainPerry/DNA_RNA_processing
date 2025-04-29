WAITFOR=":1"
if [ "$SKIPQCTRIM" = "TRUE" ]; then
    echo "$(date '+%F %T') - Skipping Trimming" >> $log_file
else
    for i in $SamplesRaw; do
        echo "$(date '+%F %T') - Starting trimming job ${i}" >> $log_file

        if [ "$RUNTYPE" = "PE" ]; then
            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF fastp \
                --in1 $TMP/${i}_M_F.fq.gz \
                --in2 $TMP/${i}_M_R.fq.gz \
                --out1 $TRIM/${i}_trimmed_F.fq.gz \
                --out2 $TRIM/${i}_trimmed_R.fq.gz \
                --thread 2 \
                -h $LOGS/trim/${i}_fastp.html \
                -j $LOGS/trim/${i}_fastp.json \
                2> "$LOGS/trim/${i}_trim.err" \
                > "$LOGS/trim/${i}_trim.out"
        else
            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF fastp \
                --in1 $TMP/${i}_M_F.fq.gz \
                --out1 $TRIM/${i}_trimmed_F.fq.gz \
                --thread 2 \
                -h $LOGS/trim/${i}_fastp.html \
                -j $LOGS/trim/${i}_fastp.json \
                2> "$LOGS/trim/${i}_trim.err" \
                > "$LOGS/trim/${i}_trim.out"
        fi

    done
fi

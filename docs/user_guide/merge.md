```
destination_dir="$Base/$JobID/tmp"
# Check if merging is skipped
if [ "$SKIPMERGE" = "TRUE" ]; then
    echo "$(date '+%F %T') - Linking Files" >> "$log_file"
    if [ "$RUNTYPE" = "SE" ]; then
        for i in $SamplesRaw; do
            dest_file="${destination_dir}/${i}_M_F.fq.gz"
            if [ ! -s "$dest_file" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawSE}" "$dest_file"
            fi
        done
    elif [ "$RUNTYPE" = "PE" ]; then
        for i in $SamplesRaw; do
            dest_file_f="${destination_dir}/${i}_M_F.fq.gz"
            dest_file_r="${destination_dir}/${i}_M_R.fq.gz"
            if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawF}" "$dest_file_f"
                ln -s -f "$DataRaw/${i}*${SuffixRawR}" "$dest_file_r"
            fi
        done
    else
        echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
        exit 1
    fi
else
    # Loop through each sample name
    while IFS= read -r sample_name; do
        dest_file_f="${destination_dir}/${sample_name}_M_F.fq.gz"
        dest_file_r="${destination_dir}/${sample_name}_M_R.fq.gz"
        if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
            if [ "$RUNTYPE" = "SE" ]; then
                files_se=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawSE}")
                if [ -n "$files_se" ]; then
                    for file in $files_se; do
                        cat "$file" >> "$dest_file_f"
                    done
                    echo "$(date '+%F %T') - Merged single-end files for $sample_name" >> "$log_file"
                else
                    echo "$(date '+%F %T') - No single-end files found for $sample_name" >> "$log_file"
                fi
            elif [ "$RUNTYPE" = "PE" ]; then
                files_r1=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawF}")
                files_r2=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawR}")
                if [ -n "$files_r1" ] && [ -n "$files_r2" ]; then
                    for file_r1 in $files_r1; do
                        cat "$file_r1" >> "$dest_file_f"
                        echo "$(date '+%F %T') - Merged R1 files for $sample_name" >> "$log_file"
                    done
                    for file_r2 in $files_r2; do
                        cat "$file_r2" >> "$dest_file_r"
                        echo "$(date '+%F %T') - Merged R2 files for $sample_name" >> "$log_file"
                    done
                else
                    echo "$(date '+%F %T') - No R1 or R2 files found for $sample_name" >> "$log_file"
                fi
            else
                echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
                exit 1
            fi
        else
            echo "$(date '+%F %T') - Skipping merge for $sample_name as destination files already exist and have non-zero size" >> "$log_file"
        fi
    done <<< "$SamplesRaw"
fi
```

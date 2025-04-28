# Merging
When sequencing samples, it is common for the data to be split across multiple lanes of a sequencer. This division can help balance the sequencing load and manage large datasets. However, this means a single biological sample often results in multiple FASTQ files — one per lane.

Merging combines these separate FASTQ files into a single file before proceeding to mapping or alignment.
Merging at the FASTQ level (before mapping) is generally acceptable because modern sequencers have very low lane-to-lane variability, minimizing concerns about introducing bias.

Historically, there was debate about when merging should occur:
+ Earlier sequencers occasionally produced lane-specific artifacts (e.g., differences in duplication levels), so some workflows recommended mapping each lane separately and merging at the BAM stage.
+ With current high-quality sequencing platforms, these artifacts are rare. As a result, merging before mapping simplifies the workflow, reduces computation time, and typically has no negative effect on downstream analyses.
+ Merging early simplifys downstream analysis. Sometimes you may have multiple lanes to merge, sometimes you don't. Merging at this step makes it missed merges less likely.
  
### Stage check
Bioinformatics can generate lots of intermediary files. Getting rid of those files at the end of the analysis saves on digital space, and keeps things clean.
As the merge will immediately flow into trimming, we dont need to keep merged files for very long so we can merge lanes into a temporary directory.
```
destination_dir="$Base/$JobID/tmp"
```

We can now check if in our options we have specified. The ***if*** statement checks if the variable set earlier ***SKIPMERGE*** is equal to TRUE. If it is, then we can skip merging.
Instead we only need to generate links to the files, so the next stage knows where to look
We add in an * *echo* * to print the date and time as well as a message to our log, so we can see what step is being done.
```
if [ "$SKIPMERGE" = "TRUE" ]; then
    echo "$(date '+%F %T') - Linking Files" >> "$log_file"
```

## File link
### Runtype check
Following our skip check, we are assuming in this next step we are skipping merging. We now want to check if we are dealing with Single End sequencing or Paired End sequencing.
The ***if*** statement works exactly the same way as before. We start with Single End processing.
This time if it is true, we are going to use a loop to link files.
The ***for*** loop defines `i` to be the list of samples we are analysing. 
It will ***do***, setting a temp variable `dest_file` to be our `tmp` directory and the sample name.

Our nested ***if*** statement does a quick check. if the link or file already exists, using `!` then we dont need to replace it.
Otherwide we use a symlink to the files actual location [^1].

```
    if [ "$RUNTYPE" = "SE" ]; then
        for i in $SamplesRaw; do
            dest_file="${destination_dir}/${i}_M_F.fq.gz"
            if [ ! -s "$dest_file" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawSE}" "$dest_file"
            fi
        done
```
If we are not doing SE analysis but PE, our ***elif*** will run the same process of generating symlinks.
```
    elif [ "$RUNTYPE" = "PE" ]; then
        for i in $SamplesRaw; do
            dest_file_f="${destination_dir}/${i}_M_F.fq.gz"
            dest_file_r="${destination_dir}/${i}_M_R.fq.gz"
            if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
                ln -s -f "$DataRaw/${i}*${SuffixRawF}" "$dest_file_f"
                ln -s -f "$DataRaw/${i}*${SuffixRawR}" "$dest_file_r"
            fi
        done
```
If we have not defined `RUNTYPE` as ***SE*** or ***PE*** then we will not know what steps to do throughout the pipeline, so an exit code of 1 will kill the whole script
```
    else
        echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
        exit 1
    fi
```
## File merge
### Merge setup
The ***while IFS*** statement actually finishes with ***<<<"$SamplesRaw"***
In truth it is probably best that the previous loop should also use a ***while*** loop, but it is a good demonstration on its use.

| **Feature**     | **`for` loop**           | **`while` loop**       |
| Splitting   | Splits on whitespace | Line-by-line       |
| Spaces      | Breaks filename      | Can handle spaces  |
| Empty lines | Skips empty lines    | Reads empty lines  |
| Memory      | Loads entire list    | One line at a time |
| Safety      | Can crash            | Safer for big list |
|Preference   | Quick & simple       | Better for complex |

Like with linking, we first setup what the output single files will be. In this case we are defining for forward and reverse at the begining.
We also have a check for if the files exist. If they already exist we either forgot to run skip on this section, or we are dealing with a failed run.
+ In the case of a failed run, manual removal of the existing files may be necessary.
```
else
    # Loop through each sample name
    while IFS= read -r sample_name; do
        dest_file_f="${destination_dir}/${sample_name}_M_F.fq.gz"
        dest_file_r="${destination_dir}/${sample_name}_M_R.fq.gz"
        if [ ! -s "$dest_file_f" ] || [ ! -s "$dest_file_r" ]; then
```
Like with linking, we then run code for SE and PE. Here SE ***files_se*** is set by running a nested function.
That function `find`s all of our samples within a directory accounting for fluctuating names that may be lane numbers.
e.g. Sample1_lane1_F.fq and Sample1_lane2_F.fq

We use `> "$dest_file_f"` to serve two functions. It is a secondary stopcheck to stop addition of fastq files to previous data it shouldn't.
(though this should be stopped previously by `if [ !`)
It also sets up the file ready for concatination. Its not strictly necessary but its another example of a system check.

We then use `cat "$file" >> "$dest_file_f"` to write the contents of all found fastq files into one single output fastq.
N.B. `>` overwrites outputs into, while `>>` adds to the end of outputs
```
            if [ "$RUNTYPE" = "SE" ]; then
                files_se=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawSE}")
                if [ -n "$files_se" ]; then
                    > "$dest_file_f"
                    for file in $files_se; do
                        cat "$file" >> "$dest_file_f"
                    done
                    echo "$(date '+%F %T') - Merged single-end files for $sample_name" >> "$log_file"
                else
                    echo "$(date '+%F %T') - No single-end files found for $sample_name" >> "$log_file"
                fi
```
We now do the same for PE.
You'll note with SE and PE we have lots of ***echo*** comments to keep us informed in the logfile.

```
            elif [ "$RUNTYPE" = "PE" ]; then
                files_r1=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawF}")
                files_r2=$(find "$DataRaw" -type f -name "${sample_name}${SuffixRawR}")
                if [ -n "$files_r1" ] && [ -n "$files_r2" ]; then
                    > "$dest_file_f"
                    > "$dest_file_r"
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
```
Like with the link, we want an exit code for an invalid runtype
```
            else
                echo "$(date '+%F %T') - Invalid RUNTYPE: $RUNTYPE" >> "$log_file"
                exit 1
            fi
```
Finally have the message informing us of skipping if we already have files genereated. If we go back to that perhaps unnecessary `> "$dest_file_f"`,
we could look to modify to check existing files they are not truncated.
```
        else
            echo "$(date '+%F %T') - Skipping merge for $sample_name as destination files already exist and have non-zero size" >> "$log_file"
        fi
    done <<< "$SamplesRaw"
fi
```
[^1]: You may also note we are keeping the file naming structure consistent, even if we don't need to merge files by naming the symlinks.

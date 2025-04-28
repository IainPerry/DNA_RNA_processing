# SNP Variant Calling

### Logic
First step is defining if we are interested in germline mutations, or somatic mutations.
"GATK is the Gold standard" is a quote by GATK about GATK. Historically this was true and it certainly is a stick to measure others aginst.
But newer tools are just as effective and significantly faster and more straightforward to run.

DeepVariant and DeepSomatic offer a machine learning-based approach to variant calling that has shown improved accuracy, particularly in calling SNPs and indels, compared to traditional methods like GATK.
+ DeepVariant: Designed for both germline and somatic variant calling, it leverages a deep neural network to more effectively identify variants, particularly in challenging regions of the genome.
  It outperforms traditional methods like GATK HaplotypeCaller in terms of accuracy and sensitivity, especially for difficult-to-call variants.
+ DeepSomatic: Specifically designed for somatic variant calling, and it is tailored to identify mutations in cancer samples, where the variants of interest are typically low-frequency and buried in a large amount of normal DNA.
```
WAITFOR4="$WAITFOR4:1"
if [ "$SKIPSNP" = "TRUE" ]; then
  echo "$(date '+%F %T') - Skipping Variant calling" >> "$log_file"

else
```
### DeepSomatic
Deep Somatic requires the additional use of a table file that says what tumour sample is matched to non-tumour sample. 
i.e. we are comparing the difference between two samples. 
To explain this a bit better, we have germline mutations from birth, if we are interested in cancer for example, we may not care about some mutations.
i.e. those cancer causing mutations that we have acquired. If we have 105 mutations in our cancer sample and 100 in our germline, we effectively go 105-100=5. Those 5 we hope are the cause that we can investigate.
```
  if [ "$SNPCALLING" = "Somatic" ]; then
    echo "$(date '+%F %T') - Starting Somatic Variant calling" >> "$log_file"

    if [ "$Species" = "Human" ]; then
      FASTAref="$FASTArefH"
    else
      FASTAref="$FASTArefM"
    fi

    while IFS= read -r line; do
      wait_for_slot
      sample=$(echo "$line" | awk '{print $1}')
      matched_sample=$(echo "$line" | awk '{print $2}')

      echo "$(date '+%F %T') - Running somatic process with tumor: $sample, normal: $matched_sample" >> "$log_file"

      vcf_file="$VCF/${sample}_somatic_variants.vcf.gz"
      stats_file="$LOGS/VCF/${sample}_tumor.stats"

      if [ ! -f "$vcf_file" ]; then
        RETVAL=$(sbatch \
          --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time=0-8:00 \
          --error="$LOGS/VCF/slurm_${sample}_index.err" --output="$LOGS/VCF/slurm_${sample}_index.out" \
          --dependency=afterok${WAITFOR3} \
          --wrap="module load $SINGULARITY

            mkdir -p $TMP/${sample}_somatic
```
For deepsomatic
+ we specify the `model_type` being WGS or WES
+ we speify the reference to compare against
+ we specify our normal sample
+ we specify our tumor sample
+ we specify our output VCF file
+ we specify out output gvcf which is useful for combining vcf files
+ we define the number of cpu threads
+ we specify a tmp directory
+ we specify the name of our normal sample
+ we specify the name of our tumor sample
```
            singularity exec $DEEPS_SIF run_deepsomatic \
              --model_type=$MODEL \
              --ref=$FASTAref \
              --reads_normal=$BAM/${matched_sample}.bam \
              --reads_tumor=$BAM/${sample}.bam \
              --output_vcf=$VCF/${sample}_somatic_variants.vcf.gz \
              --output_gvcf=$VCF/${sample}_somatic_variants.g.vcf.gz \
              --num_shards=8 \
              --intermediate_results_dir=$TMP/${sample}_somatic \
              --sample_name_normal=${matched_sample}_normal \
              --sample_name_tumor=${sample}_tumor
```
### BCFtools
We can additionally perform some stats on the generated VCF files
```

            singularity exec $BCFTOOLS_SIF bcftools stats \
              $VCF/${sample}_somatic_variants.vcf.gz > $LOGS/VCF/${sample}_tumor.stats
          ")

        JOBID=$(echo "$RETVAL" | sed "s/Submitted batch job //")
        WAITFOR4="${WAITFOR4}:${JOBID}"

      else
        echo "$(date '+%F %T') - Skipping $sample: VCF already exists at $vcf_file" >> "$log_file"
      fi

    done < "$SOMATIC_TABLE"

  else
    for i in $SamplesRaw; do
        wait_for_slot
        echo "$(date '+%F %T') - Starting Germline Variant calling job ${i}" >> "$log_file"

      if [ "$Species" = "Human" ]; then
        FASTAref="$FASTArefH"
      else
        FASTAref="$FASTArefM"
      fi
      
      if [ ! -f "$vcf_file" ]; then
      RETVAL=$(sbatch \
        --account=${SLURM_ACCOUNT} --nodes=1 --ntasks-per-node=1 --cpus-per-task=8 --time=0-8:00 \
        --error="$LOGS/VCF/slurm_${i}_index.err" --output="$LOGS/VCF/slurm_${i}_index.out" \
        --dependency=afterok${WAITFOR3} \
        --wrap="module load $SINGULARITY

          mkdir -p $TMP/${i}
```
### Deepvariant
And similarly we now run for deepvariant. If we are only interested in all mutations, this is a faster and easier option.
```

          singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $DEEPV_SIF run_deepvariant \
            --model_type=$MODEL \
            --ref=$FASTAref \
            --reads=$BAM/${i}.bam \
            --output_vcf=$VCF/${i}_variants.vcf.gz \
            --output_gvcf=$VCF/${i}_variants.g.vcf.gz \
            --num_shards=8 \
            --intermediate_results_dir=$TMP/${i} \
            --sample_name=${i}

          singularity exec $BCFTOOLS_SIF bcftools stats \
            $VCF/${i}_variants.vcf.gz > $LOGS/VCF/${i}.stats
        ")

      JOBID=$(echo "$RETVAL" | sed "s/Submitted batch job //")
      WAITFOR4="${WAITFOR4}:${JOBID}"
      else
        echo "$(date '+%F %T') - Skipping $sample: VCF already exists at $vcf_file" >> "$log_file"
      fi
    done
  fi
fi

echo "$WAITFOR4"
```

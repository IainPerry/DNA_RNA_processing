#!/bin/bash
# Script to build all required SIFs - comment out any you don't need

singularity remote login

# Optional
#singularity remote list
#singularity remote use cloud.sylabs.io


# Build fastp
singularity build --remote fastp-v0.23.1.sif fastp-v0.23.1.def

# Build STAR
# singularity build --remote STAR-2.7.9a.sif STAR-2.7.9a.def

# Build BWA
# singularity build --remote bwa-0.7.17.sif bwa-0.7.17.def

# Build Samtools
# singularity build --remote samtools-1.9.sif samtools-1.9.def

# Build featureCounts
# singularity build --remote featurecounts-2.0.3.sif featurecounts-2.0.3.def

# Build DeepVariant
# singularity build --remote deepvariant_1.3.0.sif deepvariant_1.3.0.def

# Build DeepSomatic
# singularity build --remote deepsomatic_1.6.0.sif deepsomatic_1.6.0.def

# Build BCFtools
# singularity build --remote bcftools_v1.10.2.sif bcftools_v1.10.2.def


# Build PICARD
# singularity build --remote picard-2.27.4.sif picard-2.27.4.def

# Build QUALIMAP
# singularity build --remote qualimap_v2.2.1.sif qualimap_v2.2.1.def

# Build MULTIQC
# singularity build --remote multiqc-v1.11.sif multiqc-v1.11.def

###################### Under Dev #################################
# Build VEP
# singularity build --remote ensembl-vep-105.sif ensembl-vep-105.def
# module load singularity
# singularity exec vep_nocache.sif vep_install --AUTO cf --SPECIES homo_sapiens --ASSEMBLY GRCh38 --CACHEDIR /VEP/homo_sapiens
# singularity exec vep_nocache.sif vep_install --AUTO cf --SPECIES mus_musculus --ASSEMBLY GRCm39 --CACHEDIR /VEP/mus_musculus



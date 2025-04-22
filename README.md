# RNA/DNA Variant Calling Pipeline

A modular SLURM-based pipeline for processing high-throughput sequencing data — Options including:
-  QC and trimming raw FASTQ
-  Alignment
-  Mapping
-  Feature quantification
-  Variant calling (germline or somatic)

Built to support human and mouse data with runtime checks and SLURM job chaining.

---
Why does this use Bash rather than the 'cooler' Nextflow or Snakemake tools.
Primarily this is for bespoke projects, not for regular/run of the mill pipelines run exactly the same way day in day out.
Secondly this is used to help teach novice coders some of the basics, so it's designed to be slighly easier to break apart.

| **Feature**                   | **Bash**                                              | **Nextflow**                                           | **Snakemake**                                           |
|-------------------------------|------------------------------------------------------|------------------------------------------------------|-------------------------------------------------------|
| **Simplicity and Learnability** | ✓ Simple, easy to teach, no extra dependencies needed. | ✗ Steeper learning curve due to Nextflow DSL.         | ✗ Requires learning a custom DSL for workflow logic.   |
| **Flexibility and Control**    | ✓ Full control over script logic, manual handling.    | ✗ Abstracted control, less granular control.          | ✓ Flexible, highly configurable, but some abstraction. |
| **Resource Management**        | ✓ Manual control of resources (e.g., SLURM).          | ✓ Advanced built-in resource management and scaling.   | ✓ Built-in resource management for scalability.        |
| **Debugging and Development**  | ✓ Easier to debug, errors are visible in script.      | ✗ Can be harder to debug due to abstraction.          | ✓ Easier than Nextflow; more transparent errors.       |
| **Minimal Dependencies**       | ✓ No dependencies beyond the shell environment.       | ✗ Requires installation of Nextflow.                  | ✗ Requires Snakemake installation and dependencies.    |
| **Transparency and Portability** | ✓ Scripts are transparent and easy to share.          | ✗ Harder to share due to Nextflow-specific configurations. | ✗ Requires setup for reproducibility and sharing.     |
| **Parallelism and Scalability** | ✗ Manual parallelism setup, not scalable for large datasets. | ✓ Automatic parallelism and scalability.              | ✓ Built-in parallelism, highly scalable.               |
| **Community Support**          | ✓ Broad community, but not bioinformatics-specific.   | ✓ Growing support in bioinformatics.                  | ✓ Strong bioinformatics community with many workflows. |
| **Reproducibility**            | ✗ Depends on the environment and script setup.        | ✓ Highly reproducible with containers and environment management. | ✓ Ensures reproducibility via dependency tracking.    |
| **Suitability for Bioinformatics** | ✓ Good for small pipelines or single tasks.            | ✓ Great for complex pipelines with multiple dependencies. | ✓ Excellent for bioinformatics, integrates with tools. |


---

## Project Structure

```
project/
├── raw/                # Raw FASTQ input files
├── tmp/                # Temporary files
├── trim/               # Trimmed reads (fastp)
├── bam/                 # Aligned BAM files
├── counts/             # FeatureCounts output
├── vcf/                # DeepVariant/DeepSomatic VCFs
├── logs/               # Logs for SLURM and tools
└── SIFS/            # Main and helper scripts
```

---

## Quick Start

### 0. Dependencies

- Singularity

Future development could include options for Local install, Conda and Docker.

### 1. Setup

```
git clone https://github.com/IainPerry/DNA_RNA_processing.git

#Optionally
cd SIF
chmod +x make_sifs.sh
./make_sifs.sh

```

Ensure modules or paths for `Singularity`, `SLURM`, and SIF containers are available.
DEF files are available for container generation.

Update configuration variables in `pipeline.sh`.

```bash
# Run the pipeline interactively, in background
nohup bash pipeline.sh &
disown
```
It is recommended at first you try running interactively before disowning to check correct running.

### 2. Input Requirements

- FASTQ files: `${Sample}_M_F.fq.gz`, `${Sample}_M_R.fq.gz`
- Optional `SOMATIC_TABLE.txt`:
  ```
  tumor1 normal1
  tumor2 normal2
  ```

---

## Pipeline Stages

| Step            | Tool                          | Output                            |
| --------------- | ----------------------------- | --------------------------------- |
| Trimming + QC   | `fastp`                       | Trimmed reads + HTML/JSON reports |
| Alignment       | `STAR` or `BWA`               | BAM files                         |
| Counting        | `featureCounts`               | Gene count tables                 |
| Variant Calling | `DeepVariant` / `DeepSomatic` | VCF files                         |
| Stats           | `bcftools stats`              | `.stats` files                    |
| Aggregation     | `MultiQC`                     | Unified QC HTML report            |

---

## Configurable Options

| Variable          | Description                           | Example            |
| ----------------- | ------------------------------------- | ------------------ |
| `RUNTYPE`         | `PE` or `SE`                          | `PE`               |
| `SNPCALLING`      | `Germline` or `Somatic`               | `Somatic`          |
| `MODEL`           | DeepVariant model type                | `WGS`, `WES`       |
| `Species`         | Reference species                     | `Human` or `Mouse` |
| `FASTArefH`/`M`   | Paths to human/mouse FASTA references | `/path/ref.fa`     |
| `Base`, `SIF_DIR` | Mounted directories for Singularity   |                    |
| `SOMATIC_TABLE`   | Path to matched tumor/normal table    | `./samples.txt`    |

---

## MultiQC Aggregates

The pipeline collects and aggregates the following into a final report:

- **fastp**: read trimming efficiency, quality distributions
- **STAR / BWA**: alignment summary
- **featureCounts**: assignment stats
- **bcftools stats**: variant calling summaries
- Optionally: Extend with FastQC, RSeQC, Picard

---

## Example Output

```bash
logs/
├── trim/
│   ├── sample1_fastp.html
│   └── sample1_fastp.json
├── VCF/
│   ├── sample1.stats
│   └── slurm_sample1_index.out
multiqc/
└── multiqc_report.html
```

---

## Contributions

Iain Perry

(Peter Giles - Some SIF recipies)

Additional planned stages include:
- Greater depth of QC metrics
- Dynamic outputting to webbased tools like Django

---

## License

MIT License — free to use and adapt with attribution.

---


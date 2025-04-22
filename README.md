# RNA/DNA Variant Calling Pipeline

A modular SLURM-based pipeline for processing high-throughput sequencing data — Options including:
-  QC and trimming raw FASTQ
-  Alignment
-  Mapping
-  Feature quantification
-  Variant calling (germline or somatic)

Built to support human and mouse data with runtime checks and SLURM job chaining.

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

### 1. Setup

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

Additional planned stages include:
- Greater depth of QC metrics
- Dynamic outputting to webbased tools like Django

---

## 📖 License

MIT License — free to use and adapt with attribution.

---


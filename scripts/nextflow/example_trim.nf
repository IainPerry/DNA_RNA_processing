process trim_reads {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads_fq1), path(reads_fq2)

    output:
    tuple val(sample_id), path("${sample_id}_trimmed_F.fq.gz"), path("${sample_id}_trimmed_R.fq.gz")

    script:
    def out_html = "${params.Base}/${params.JobID}/logs/trim/${sample_id}_fastp.html"
    def out_json = "${params.Base}/${params.JobID}/logs/trim/${sample_id}_fastp.json"

    """
    singularity exec --bind ${params.Base}:${params.Base} --bind ${params.SIF_DIR}:${params.SIF_DIR} ${params.FASTP_SIF} fastp \
        --in1 $reads_fq1 \
        --in2 $reads_fq2 \
        --out1 ${sample_id}_trimmed_F.fq.gz \
        --out2 ${sample_id}_trimmed_R.fq.gz \
        --thread 2 \
        -h ${out_html} \
        -j ${out_json}
    """
}

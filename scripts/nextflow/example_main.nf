// main.nf

// Import each module script
include { TRIM } from './bin/trim.nf'
include { RNA_MAP } from './bin/rna_map.nf'
include { DNA_MAP } from './bin/dna_map.nf'
include { INDEX } from './bin/index.nf'
include { FEATCOUNT } from './bin/featcount.nf'
include { VARIANT } from './bin/variant.nf'

// Initialize log
log_file = "${params.base}/${params.job_id}/pipeline.log"

workflow {
    // Project Setup
    def base = file(params.base)
    def jobid = params.job_id
    def logs = "${base}/${jobid}/logs"
    def dirs = [
        "${base}/${jobid}",
        "${logs}/trim",
        "${logs}/bam",
        "${logs}/VCF",
        "${logs}/counts",
        "${base}/${jobid}/bam",
        "${base}/${jobid}/trim",
        "${base}/${jobid}/tmp",
        "${base}/${jobid}/VCF",
        "${base}/${jobid}/counts"
    ]

    dirs.each { dir ->
        file(dir).mkdirs()
    }
    log.info "Directories created"

    // Merge Setup
    def tmpDir = file("${base}/${jobid}/tmp")
    def samplesRaw = params.samples_raw.split("\n")

    if (params.skip_merge == true) {
        log.info "Linking files (SKIPMERGE=TRUE)"
        samplesRaw.each { i ->
            if (params.runtype == "SE") {
                def dest = tmpDir.resolve("${i}_M_F.fq.gz")
                if (!dest.exists()) {
                    def src = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_se) }
                    dest.createLink(src)
                }
            } else {
                def destF = tmpDir.resolve("${i}_M_F.fq.gz")
                def destR = tmpDir.resolve("${i}_M_R.fq.gz")
                if (!destF.exists()) {
                    def srcF = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_f) }
                    destF.createLink(srcF)
                }
                if (!destR.exists()) {
                    def srcR = file(params.data_raw).listFiles().find { it.name.contains(i) && it.name.endsWith(params.suffix_raw_r) }
                    destR.createLink(srcR)
                }
            }
        }
    } else {
        log.info "Merging files (SKIPMERGE=FALSE)"
        samplesRaw.each { sample ->
            if (params.runtype == "SE") {
                def dest = tmpDir.resolve("${sample}_M_F.fq.gz")
                if (!dest.exists()) {
                    def srcs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_se) }
                    def merged = dest.newOutputStream()
                    srcs.each { file -> file.eachLine { merged << it + '\n' } }
                    merged.close()
                }
            } else {
                def destF = tmpDir.resolve("${sample}_M_F.fq.gz")
                def destR = tmpDir.resolve("${sample}_M_R.fq.gz")
                if (!destF.exists() || !destR.exists()) {
                    def srcFs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_f) }
                    def srcRs = file(params.data_raw).listFiles().findAll { it.name.contains(sample) && it.name.endsWith(params.suffix_raw_r) }
                    def outF = destF.newOutputStream()
                    def outR = destR.newOutputStream()
                    srcFs.each { file -> file.eachLine { outF << it + '\n' } }
                    srcRs.each { file -> file.eachLine { outR << it + '\n' } }
                    outF.close()
                    outR.close()
                }
            }
        }
    }

    // Conditional step execution
    if (!params.skipqctrim) {
        TRIM()
    }
    if (!params.skip_rna_map) {
        RNA_MAP()
    }
    if (!params.skip_dna_map) {
        DNA_MAP()
    }
    if (!params.skipindex) {
        INDEX()
    }
    if (!params.skipfc) {
        FEATCOUNT()
    }
    if (!params.skipsnp) {
        VARIANT()
    }
}

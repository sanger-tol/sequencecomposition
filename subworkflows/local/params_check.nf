//
// Check and parse the input parameters
//

include { GUNZIP            } from '../../modules/nf-core/gunzip/main'
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow PARAMS_CHECK {

    take:
    samplesheet  // file
    cli_params   // tuple, see below
    outdir       // file output directory


    main:
    ch_versions = Channel.empty()

    ch_inputs = Channel.empty()
    if (samplesheet) {
        SAMPLESHEET_CHECK ( file(samplesheet, checkIfExists: true) )
            .csv
            // Provides outdir and fasta
            .splitCsv ( header:true, sep:',' )
            .map { [
                (it["outdir"].startsWith("/") ? "" : outdir + "/") + it["outdir"],
                it["fasta"],
            ] }
            .set { ch_inputs }

        ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)

    } else {
        // Add the other input channel in, as it's expected to have all the parameters in the right order
        ch_inputs = ch_inputs.mix(cli_params.map { [outdir] + it } )
    }

    ch_input_files = ch_inputs.map { outdir, fasta ->
        file_fasta = file(fasta, checkIfExists: true)
        return [
            [
                id: file_fasta.baseName,
                outdir: outdir,
            ],
            file_fasta,
        ]
    }

    // Only flow to gunzip when required
    ch_parsed_fasta_name = ch_input_files.branch {
        meta, filename ->
            compressed : filename.getExtension().equals('gz')
            uncompressed : true
    }

    // gunzip .fa.gz files
    ch_unzipped_fasta   = GUNZIP ( ch_parsed_fasta_name.compressed ).gunzip
    ch_versions         = ch_versions.mix(GUNZIP.out.versions.first())

    // Combine with preexisting .fa files
    ch_plain_fasta      = ch_parsed_fasta_name.uncompressed.mix(ch_unzipped_fasta)


    emit:
    plain_fasta = ch_plain_fasta       // channel: [ val(meta), path/to/fasta ]
    versions    = ch_versions          // channel: versions.yml
}


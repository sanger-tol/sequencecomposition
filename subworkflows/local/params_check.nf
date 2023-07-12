//
// Check and parse the input parameters
//

include { GUNZIP            } from '../../modules/nf-core/gunzip/main'
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow PARAMS_CHECK {

    take:
    inputs          // tuple, see below


    main:

    def (samplesheet, fasta, outdir) = inputs

    ch_versions = Channel.empty()

    ch_inputs = Channel.empty()
    if (samplesheet) {

        SAMPLESHEET_CHECK ( file(samplesheet, checkIfExists: true) )
            .csv
            // Provides species_dir and assembly_name
            .splitCsv ( header:true, sep:',' )
            // Add assembly_path, following the Tree of Life directory structure
            .map {
                it + [
                    assembly_path: "${it["species_dir"]}/assembly/release/${it["assembly_name"]}/insdc",
                    ]
            }
            .map {
                // If assembly_accession is missing, load the accession number from file, following the Tree of Life directory structure
                it["assembly_accession"] ? it : it + [
                    assembly_accession: file("${it["assembly_path"]}/ACCESSION", checkIfExists: true).text.trim(),
                ]
            }
            // Convert to tuple(meta,file) as required by GUNZIP and FASTAWINDOWS
            .map { [
                [
                    id: it["assembly_accession"],
                    analysis_dir: "${it["species_dir"]}/analysis/${it["assembly_name"]}",
                ],
                file("${it["assembly_path"]}/${it["assembly_accession"]}.fa.gz", checkIfExists: true),
            ] }
            .set { ch_inputs }

        ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)

    } else {

        file_fasta = file(fasta, checkIfExists: true)
        ch_inputs = Channel.of(
            [
                [
                    id: file_fasta.baseName,
                    analysis_dir: outdir,
                ],
                file_fasta,
            ]
        )

    }

    // Only flow to gunzip when required
    ch_parsed_fasta_name = ch_inputs.branch {
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


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
            // Provides species_dir and assembly_name
            .splitCsv ( header:true, sep:',' )
            .map {
                it + [
                    ]
            }
            .map { make_input_tuple(it, outdir) }
            .set { ch_inputs }

        ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)

    } else {

        ch_inputs = cli_params.map {
             file(it[0], checkIfExists: true)
        } .map { file_fasta ->
            [
                [
                    id: file_fasta.baseName,
                    analysis_dir: outdir,
                ],
                file_fasta,
            ]
        }

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


// Generate a tuple(meta,file) as required by GUNZIP and FASTAWINDOWS
def make_input_tuple(row, outdir) {

    if (row.fasta && row.assembly_accession) {
        Nextflow.error "Fasta and accession can't be provided at the same time"
    }

    // Add outdir to species_dir, if needed
    def species_dir = (row.species_dir.startsWith("/") ? "" : outdir + "/") + row.species_dir
    // Derive the analysis directory
    def analysis_dir = "${species_dir}/analysis/${row.assembly_name}"

    // If a Fasta is provided, just use it
    if (row.fasta) {
        return [
            [
                id: row.assembly_name,
                analysis_dir: analysis_dir,
            ],
            file(row.fasta, checkIfExists: true),
        ]

    } else {
        // Assembly path, following the Tree of Life directory structure
        def assembly_path = "${species_dir}/assembly/release/${row.assembly_name}/insdc"
        // If assembly_accession is missing, load the accession number from file, following the Tree of Life directory structure
        def assembly_accession = row.assembly_accession ?: file("${assembly_path}/ACCESSION", checkIfExists: true).text.trim()
        return [
            [
                id: assembly_accession,
                analysis_dir: analysis_dir,
            ],
            file("${assembly_path}/${assembly_accession}.fa.gz", checkIfExists: true),
        ]
    }
}

//
// Check and parse the input parameters
//

include { SAMTOOLS_FAIDX       } from '../../modules/nf-core/samtools/faidx/main'
include { GUNZIP               } from '../../modules/nf-core/gunzip/main'

workflow PARAMS_CHECK {

    take:
    samplesheet  // tuple (outdir, fasta) -- parsed samplesheet

    main:
    ch_versions = channel.empty()

    ch_parsed_fasta_name = samplesheet
        .map { outdir, fasta ->
            // Trick to strip the Fasta extension for gzipped files too, without having to list all possible extensions
            def id = file(fasta.name.replace(".gz", "")).baseName
            return [
                [
                    id: id,
                    outdir: outdir,
                ],
                fasta,
                file(fasta.toUriString() + ".fai"),
            ]
        }
        .branch {
            _meta, fasta, _fai ->
                compressed : fasta.getExtension().equals('gz')      // (meta, fasta_gz, fai)
                uncompressed : true                                 // (meta, fasta, fai)
        }

    // uncompress them, with some channel manipulations to maintain the triplet (meta, fasta, fai)
    gunzip_input        = ch_parsed_fasta_name.compressed.map { meta, fasta_gz, _fai -> [meta, fasta_gz] }
    ch_unzipped_fasta   = GUNZIP(gunzip_input).gunzip                   // (meta, fasta)
                            .join(ch_parsed_fasta_name.compressed)      // joined with (meta, fasta_gz, fai) makes (meta, fasta, fasta_gz, fai)
                            .map { meta, fasta, _fasta_gz, fai -> [meta, fasta, fai] }
    ch_versions         = ch_versions.mix(GUNZIP.out.versions.first())

    // Check if the faidx index is present
    ch_inputs_checked = ch_parsed_fasta_name.uncompressed.mix(ch_unzipped_fasta).branch {
        meta, fasta, fai ->
            indexed : fai.exists()
            notindexed : true
                return [meta, fasta]    // remove fai from the channel because it will be added by SAMTOOLS_FAIDX below
    }

    // Generate Samtools index and chromosome sizes file, again with some channel manipulations
    ch_samtools_faidx   = ch_inputs_checked.notindexed                                          // (meta, fasta)
                            .join( SAMTOOLS_FAIDX (ch_inputs_checked.notindexed, [[], []], true).fai )    // joined with (meta, fai) makes (meta, fasta, fai)
    ch_versions         = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    // Read the .fai file, extract sequence statistics, and make an extended meta map
    ch_fasta_fai = ch_inputs_checked.indexed.mix(ch_samtools_faidx).map {
        meta, fasta, fai -> [meta + get_sequence_map(fai), fasta, fai]
    }

    emit:
    fasta_fai = ch_fasta_fai       // channel: [ val(meta), path/to/fasta, path/to/fai ]
    versions  = ch_versions        // channel: versions.yml
}

// Read the .fai file to extract the number of sequences, the maximum and total sequence length
// Inspired from https://github.com/nf-core/rnaseq/blob/3.10.1/lib/WorkflowRnaseq.groovy
def get_sequence_map(fai_file) {
    def n_sequences = 0
    def max_length = 0
    def total_length = 0
    fai_file.eachLine { line ->
        def lspl   = line.split('\t')
        // def chrom  = lspl[0]
        def length = lspl[1].toLong()
        n_sequences += 1
        total_length += length
        if (length > max_length) {
            max_length = length
        }
    }

    def sequence_map = [:]
    sequence_map.n_sequences = n_sequences
    sequence_map.total_length = total_length
    if (n_sequences) {
        sequence_map.max_length = max_length
    }
    return sequence_map
}

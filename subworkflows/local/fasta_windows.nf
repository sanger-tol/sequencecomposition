//
// Run fasta_windows and prepare all the output files
//

include { COLUMN_TO_BEDGRAPH      } from '../../modules/local/column_to_bedgraph'
include { FASTAWINDOWS            } from '../../modules/local/fastawindows'
include { TABIX_BGZIP             } from '../../modules/local/tabix_bgzip'
include { TABIX_TABIX             } from '../../modules/nf-core/modules/tabix/tabix/main'

ch_mono_config = Channel.from(
    [4,  'base_content/k1', 'GC'],
    [5,  'base_content/k1', 'GC_skew'],
    [6,  'base_content/k1', 'nucShannon'],
    [7,  'base_content/k1', 'G'],
    [8,  'base_content/k1', 'C'],
    [9,  'base_content/k1', 'A'],
    [10, 'base_content/k1', 'T'],
    [11, 'base_content/k1', 'N'],
    [12, 'base_content/k2', 'dinucShannon'],
    [13, 'base_content/k3', 'trinucShannon'],
    [14, 'base_content/k4', 'tetranucShannon'],
)

workflow FASTA_WINDOWS {

    take:
    fasta  // file: /path/to/genome.fa


    main:
    ch_versions = Channel.empty()

    // Run fasta_windows
    FASTAWINDOWS ( fasta )
    ch_versions       = ch_versions.mix(FASTAWINDOWS.out.versions)

    // Make the bedgraphs out of the frequency file
    ch_mono_bed_input = FASTAWINDOWS.out.mononuc.combine(ch_mono_config)
    ch_mono_bed       = COLUMN_TO_BEDGRAPH (
        ch_mono_bed_input.map { [it[0] + [id: it[0].id + "." + it[4], dir: it[3]], it[1]] },
        ch_mono_bed_input.map { it[2] }
    ).bedgraph
    ch_versions       = ch_versions.mix(COLUMN_TO_BEDGRAPH.out.versions)

    // Compress the BED file
    ch_compressed_bed = TABIX_BGZIP ( ch_mono_bed ).output
    ch_versions       = ch_versions.mix(TABIX_BGZIP.out.versions)

    // Index the BED file
    ch_indexed_bed    = TABIX_TABIX ( ch_compressed_bed ).tbi
    ch_versions       = ch_versions.mix(TABIX_TABIX.out.versions)


    emit:
    bedgraph = ch_compressed_bed
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}

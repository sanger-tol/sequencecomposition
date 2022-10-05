//
// Run fasta_windows and prepare all the output files
//

include { EXTRACT_COLUMN          } from '../../modules/local/extract_column'
include { FASTAWINDOWS            } from '../../modules/nf-core/modules/fastawindows/main'
include { TABIX_BGZIP             } from '../../modules/nf-core/modules/tabix/bgzip/main'
include { TABIX_TABIX as TABIX_TABIX_CSI   } from '../../modules/nf-core/modules/tabix/tabix/main'
include { TABIX_TABIX as TABIX_TABIX_TBI   } from '../../modules/nf-core/modules/tabix/tabix/main'

// List of the columns we want to extract as bedGraph from the frequency files,
// with the subdirectory name and the relevant part of the file name
ch_freq_config = Channel.of(
    [4,  'base_content/k1', 'GC'],
    [5,  'base_content/k1', 'GC_skew'],
    [6,  'base_content/k1', 'AT_skew'],
    [7,  'base_content/k1', 'nucShannon'],
    [8,  'base_content/k1', 'G'],
    [9,  'base_content/k1', 'C'],
    [10, 'base_content/k1', 'A'],
    [11, 'base_content/k1', 'T'],
    [12, 'base_content/k1', 'N'],
    [13, 'base_content/k2', 'CpG'],
    [14, 'base_content/k2', 'dinucShannon'],
    [15, 'base_content/k3', 'trinucShannon'],
    [16, 'base_content/k4', 'tetranucShannon'],
)

workflow FASTA_WINDOWS {

    take:
    fasta               // file: /path/to/genome.fa
    output_selection    // file: /path/to/fasta_windows.csv
    window_size_info    // value, used to build meta.id and name files


    main:
    ch_versions = Channel.empty()

    // Run fasta_windows
    FASTAWINDOWS ( fasta )
    ch_versions       = ch_versions.mix(FASTAWINDOWS.out.versions.first())

    Channel.of(output_selection)
        .splitCsv ( header: false )
        // tuple (channel_name,column_number,outdir,filename)
        .map { [it[1], it[2], it[3]] }
        .set { ch_config }

    // Make a combined channel: tuple(meta, freq_file_tsv, column_number, output_dir, filename),
    ch_freq_bed_input = FASTAWINDOWS.out.freq.combine(ch_config.freq)
    ch_freq_bed       = EXTRACT_COLUMN (
        // Extend meta.id to name output files appropriately, and add meta.analysis_subdir
        ch_freq_bed_input.map { [it[0] + [id: it[0].id + "." + it[4] + window_size_info, analysis_subdir: it[3]], it[1]] },
        // column number
        ch_freq_bed_input.map { it[2] }
    ).bedgraph
    ch_versions       = ch_versions.mix(EXTRACT_COLUMN.out.versions.first())

    // Add meta information to the tsv files
    ch_bed_like       = ch_freq_bed
        // Like above, extend meta.id to name output files appropriately, and add meta.analysis_subdir
        .mix( FASTAWINDOWS.out.mononuc.map  { [it[0] + [id: it[0].id + ".mononuc"  + window_size_info, analysis_subdir: "base_content/k1"], it[1]] } )
        .mix( FASTAWINDOWS.out.dinuc.map    { [it[0] + [id: it[0].id + ".dinuc"    + window_size_info, analysis_subdir: "base_content/k2"], it[1]] } )
        .mix( FASTAWINDOWS.out.trinuc.map   { [it[0] + [id: it[0].id + ".trinuc"   + window_size_info, analysis_subdir: "base_content/k3"], it[1]] } )
        .mix( FASTAWINDOWS.out.tetranuc.map { [it[0] + [id: it[0].id + ".tetranuc" + window_size_info, analysis_subdir: "base_content/k4"], it[1]] } )

    // Compress the BED file
    ch_compressed_bed = TABIX_BGZIP ( ch_bed_like ).output
    ch_versions       = ch_versions.mix(TABIX_BGZIP.out.versions.first())

    // Index the BED file in two formats for maximum compatibility
    ch_indexed_bed_csi= TABIX_TABIX_CSI ( ch_compressed_bed ).csi
    ch_versions       = ch_versions.mix(TABIX_TABIX_CSI.out.versions.first())
    ch_indexed_bed_tbi= TABIX_TABIX_TBI ( ch_compressed_bed ).tbi
    ch_versions       = ch_versions.mix(TABIX_TABIX_TBI.out.versions.first())


    emit:
    bedgraph = ch_compressed_bed
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}

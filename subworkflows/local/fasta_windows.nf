//
// Run fasta_windows and prepare all the output files
//

include { EXTRACT_COLUMN          } from '../../modules/local/extract_column'
include { FASTAWINDOWS            } from '../../modules/nf-core/modules/fastawindows/main'
include { TABIX_BGZIP             } from '../../modules/nf-core/modules/tabix/bgzip/main'
include { TABIX_TABIX as TABIX_TABIX_CSI   } from '../../modules/nf-core/modules/tabix/tabix/main'
include { TABIX_TABIX as TABIX_TABIX_TBI   } from '../../modules/nf-core/modules/tabix/tabix/main'

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

    // List of:
    // 1) the columns we want to extract as bedGraph from the frequency files,
    //    with the subdirectory name and the relevant part of the file name.
    // 2) the kmer-count files we want to load (the "column_number" column is
    //    ignored).
    Channel.of(output_selection)
        .splitCsv ( header: false )
        // tuple (channel_name,column_number,outdir,filename)
        .branch {
            freq: it[0] == "freq"
                return [it[1], it[2], it[3]]
            mononuc: it[0] == "mononuc"
                return [it[2], it[3]]
            dinuc: it[0] == "dinuc"
                return [it[2], it[3]]
            trinuc: it[0] == "trinuc"
                return [it[2], it[3]]
            tetranuc: it[0] == "tetranuc"
                return [it[2], it[3]]
        }
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
    ch_tsv = Channel.empty()
        .mix( FASTAWINDOWS.out.mononuc .combine(ch_config.mononuc) )
        .mix( FASTAWINDOWS.out.dinuc   .combine(ch_config.dinuc) )
        .mix( FASTAWINDOWS.out.trinuc  .combine(ch_config.trinuc) )
        .mix( FASTAWINDOWS.out.tetranuc.combine(ch_config.tetranuc) )
        .map { [it[0] + [id: it[0].id + "." + it[3] + window_size_info, analysis_subdir: it[2]], it[1]] }

    // Compress the BED file
    ch_compressed_bed = TABIX_BGZIP ( ch_freq_bed.mix(ch_tsv) ).output
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

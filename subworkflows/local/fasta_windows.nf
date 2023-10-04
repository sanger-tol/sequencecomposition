//
// Run fasta_windows and prepare all the output files
//

include { EXTRACT_COLUMN          } from '../../modules/local/extract_column'
include { FASTAWINDOWS            } from '../../modules/nf-core/fastawindows/main'
include { TABIX_BGZIP             } from '../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX as TABIX_TABIX_CSI   } from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_TABIX_TBI   } from '../../modules/nf-core/tabix/tabix/main'

workflow FASTA_WINDOWS {

    take:
    fasta_fai           // [file: /path/to/genome.fa, file: /path/to/genome.fai]
    output_selection    // file: /path/to/fasta_windows.csv
    window_size_info    // value, used to build meta.id and name files


    main:
    ch_versions = Channel.empty()

    // Run fasta_windows
    FASTAWINDOWS ( fasta_fai.map { meta, fasta, fai -> [meta, fasta] } )
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

    // Try indexing the BED file in two formats for maximum compatibility
    // but each has its own limitations
    tabix_selector      = ch_compressed_bed.branch { meta, bed ->
        tbi_and_csi: meta.max_length < 2**29
        only_csi:    meta.max_length < 2**32
    }

    // Do the indexing on the compatible bedGraph files
    ch_indexed_bed_csi= TABIX_TABIX_CSI ( tabix_selector.tbi_and_csi.mix(tabix_selector.only_csi) ).csi
    ch_versions       = ch_versions.mix(TABIX_TABIX_CSI.out.versions.first())
    ch_indexed_bed_tbi= TABIX_TABIX_TBI ( tabix_selector.tbi_and_csi ).tbi
    ch_versions       = ch_versions.mix(TABIX_TABIX_TBI.out.versions.first())


    emit:
    bedgraph = ch_compressed_bed
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


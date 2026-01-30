//
// Run fasta_windows and prepare all the output files
//

include { EXTRACT_COLUMN                 } from '../../modules/local/extract_column'
include { FASTAWINDOWS                   } from '../../modules/nf-core/fastawindows/main'
include { TABIX_BGZIP                    } from '../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX as TABIX_TABIX_CSI } from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_TABIX_TBI } from '../../modules/nf-core/tabix/tabix/main'

workflow FASTA_WINDOWS {
    take:
    fasta_fai // [file: /path/to/genome.fa, file: /path/to/genome.fai]
    output_selection // file: /path/to/fasta_windows.csv
    window_size_info // value, used to build meta.id and name files

    main:
    ch_versions = channel.empty()

    // Run fasta_windows
    FASTAWINDOWS(fasta_fai.map { meta, fasta, _fai -> [meta, fasta] })
    ch_versions = ch_versions.mix(FASTAWINDOWS.out.versions.first())

    // List of:
    // 1) the columns we want to extract as bedGraph from the frequency files,
    //    with the subdirectory name and the relevant part of the file name.
    // 2) the kmer-count files we want to load (the "column_number" column is
    //    ignored).
    ch_config = channel.of(output_selection)
        .splitCsv(header: false)
        .branch { channel_name, column_number, outdir, filename ->
            freq: channel_name == "freq"
            return [column_number, outdir, filename]
            mononuc: channel_name == "mononuc"
            return [outdir, filename]
            dinuc: channel_name == "dinuc"
            return [outdir, filename]
            trinuc: channel_name == "trinuc"
            return [outdir, filename]
            tetranuc: channel_name == "tetranuc"
            return [outdir, filename]
        }

    ch_freq_bed_input = FASTAWINDOWS.out.freq
        .combine(ch_config.freq)
        .multiMap { meta, freq_file_tsv, column_number, outdir, filename ->
            // Extend meta.id to name output files appropriately, and add meta.analysis_subdir
            path: [meta + [id: meta.id + "." + filename + window_size_info, analysis_subdir: outdir], freq_file_tsv]
            column_number: column_number
        }


    ch_freq_bed = EXTRACT_COLUMN(
        ch_freq_bed_input.path,
        ch_freq_bed_input.column_number,
    ).bedgraph

    ch_versions = ch_versions.mix(EXTRACT_COLUMN.out.versions.first())

    // Add meta information to the tsv files
    ch_tsv = channel.empty()
        .mix(FASTAWINDOWS.out.mononuc.combine(ch_config.mononuc))
        .mix(FASTAWINDOWS.out.dinuc.combine(ch_config.dinuc))
        .mix(FASTAWINDOWS.out.trinuc.combine(ch_config.trinuc))
        .mix(FASTAWINDOWS.out.tetranuc.combine(ch_config.tetranuc))
        .map { meta, path, outdir, filename -> [meta + [id: meta.id + "." + filename + window_size_info, analysis_subdir: outdir], path] }

    // Compress the BED file
    ch_compressed_bed = TABIX_BGZIP(ch_freq_bed.mix(ch_tsv)).output
    ch_versions = ch_versions.mix(TABIX_BGZIP.out.versions.first())

    // Try indexing the BED file in two formats for maximum compatibility
    // but each has its own limitations
    tabix_selector = ch_compressed_bed.branch { meta, _bed ->
        tbi_and_csi: meta.max_length < 2 ** 29
        only_csi: meta.max_length < 2 ** 32
    }

    // Do the indexing on the compatible bedGraph files
    ch_indexed_bed_csi = TABIX_TABIX_CSI(tabix_selector.tbi_and_csi.mix(tabix_selector.only_csi)).index
    ch_versions = ch_versions.mix(TABIX_TABIX_CSI.out.versions.first())
    ch_indexed_bed_tbi = TABIX_TABIX_TBI(tabix_selector.tbi_and_csi).index
    ch_versions = ch_versions.mix(TABIX_TABIX_TBI.out.versions.first())

    emit:
    bedgraph = ch_compressed_bed
    index    = ch_indexed_bed_csi.mix(ch_indexed_bed_tbi)
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}

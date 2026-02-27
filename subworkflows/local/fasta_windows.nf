//
// Run fasta_windows and prepare all the output files
//

include { EXTRACT_COLUMN } from '../../modules/local/extract_column'
include { FASTAWINDOWS   } from '../../modules/nf-core/fastawindows/main'
include { BGZIPTABIX     } from '../../modules/sanger-tol/bgziptabix/main'

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
            [column_number, outdir, filename]
            mononuc: channel_name == "mononuc"
            [outdir, filename]
            dinuc: channel_name == "dinuc"
            [outdir, filename]
            trinuc: channel_name == "trinuc"
            [outdir, filename]
            tetranuc: channel_name == "tetranuc"
            [outdir, filename]
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
        .mix(ch_freq_bed)

    // Compress the BED file
    ch_tsv_with_seq_length = ch_tsv.map { meta, tsv -> [meta, tsv, meta.max_length] }
    BGZIPTABIX(ch_tsv_with_seq_length)

    ch_bedgraph = BGZIPTABIX.out.gz_index
        .join(BGZIPTABIX.out.tbi, by: 0, remainder: true)
        .join(BGZIPTABIX.out.csi, by: 0, remainder: true)

    emit:
    bedgraph = ch_bedgraph
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}

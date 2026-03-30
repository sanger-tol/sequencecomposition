//
// Run fasta_windows and prepare all the output files
//

include { FASTAWINDOWS                 } from '../../modules/nf-core/fastawindows/main'
include { BGZIPTABIX as BGZIPTABIX_ALL } from '../../modules/sanger-tol/bgziptabix/main'
include { BGZIPTABIX as BGZIPTABIX_COL } from '../../modules/sanger-tol/bgziptabix/main'

workflow FASTA_WINDOWS {
    take:
    fasta_fai // [file: /path/to/genome.fa, file: /path/to/genome.fai]
    output_selection // file: /path/to/fasta_windows.csv
    window_size_info // value, used to build meta.id and name files

    main:

    // Run fasta_windows
    FASTAWINDOWS(fasta_fai.map { meta, fasta, _fai -> [meta, fasta] })

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
            path: [meta + [id: meta.id + "." + filename + window_size_info, analysis_subdir: outdir], freq_file_tsv, meta.max_length]
            column_number: ["1-3,${column_number}", 1, "bedGraph"]
        }

    BGZIPTABIX_COL(
        ch_freq_bed_input.path,
        ch_freq_bed_input.column_number,
    )
    ch_freq_bedgraph = BGZIPTABIX_COL.out.gz_index
        .join(BGZIPTABIX_COL.out.tbi, by: 0, remainder: true)
        .join(BGZIPTABIX_COL.out.csi, by: 0, remainder: true)

    // Add meta information to the tsv files
    ch_tsv = channel.empty()
        .mix(FASTAWINDOWS.out.mononuc.combine(ch_config.mononuc))
        .mix(FASTAWINDOWS.out.dinuc.combine(ch_config.dinuc))
        .mix(FASTAWINDOWS.out.trinuc.combine(ch_config.trinuc))
        .mix(FASTAWINDOWS.out.tetranuc.combine(ch_config.tetranuc))
        .map { meta, path, outdir, filename -> [meta + [id: meta.id + "." + filename + window_size_info, analysis_subdir: outdir], path] }

    // Compress the BED file
    ch_tsv_with_seq_length = ch_tsv.map { meta, tsv -> [meta, tsv, meta.max_length] }
    BGZIPTABIX_ALL(ch_tsv_with_seq_length, [false, 0, false])

    ch_bedgraph = BGZIPTABIX_ALL.out.gz_index
        .join(BGZIPTABIX_ALL.out.tbi, by: 0, remainder: true)
        .join(BGZIPTABIX_ALL.out.csi, by: 0, remainder: true)
        .mix(ch_freq_bedgraph)

    emit:
    bedgraph = ch_bedgraph
}

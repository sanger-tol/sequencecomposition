# sanger-tol/sequencecomposition: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[1.2.0](https://github.com/sanger-tol/sequencecomposition/releases/tag/1.2.0)] – Easter Bells – [2026-04-14]

### Enhancements & fixes

- Upgrade to the version 3.5.2 of the nf-core template
- Compatible with Nextflow's strict parser
- All modules updated
- The directories comply with [Tree of Life's canonical directory structure](https://pipelines.tol.sanger.ac.uk/docs/usage/gap_conventions).
- New logo, with Sanger colours
- Pipeline diagram, thanks to [nf-metro](https://pinin4fjords.github.io/nf-metro)

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| bgzip      | 1.20        | 1.21        |
| MultiQC    | 1.20        |             |
| Python     | 3.9.1       |             |
| samtools   | 1.21        | 1.23.1      |
| tabix      | 1.20        | 1.21        |

## [[1.1.0](https://github.com/sanger-tol/sequencecomposition/releases/tag/1.1.0)] – Polite Platyfish – [2024-12-10]

### Enhancements & fixes

- Upgrade to the version 2.8 of the nf-core template.
- nf-core module updates to remove Anaconda references
- Updated configuration of the GitHub CI to improve testing.
- Simpler samplesheet format, with just the path to the Fasta file and the output directory.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| bgzip      | 1.11        | 1.20        |
| MultiQC    | 1.13        | 1.20        |
| Python     | 3.8.3,3.9   | 3.9.1       |
| samtools   |             | 1.21        |
| tabix      | 1.11        | 1.20        |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.

## [[1.0.0](https://github.com/sanger-tol/sequencecomposition/releases/tag/1.0.0)] – Apophis – [2022-10-08]

Initial release of sanger-tol/sequencecomposition, created with the [nf-core](https://nf-co.re/) template.

### Enhancements & fixes

- Run `fasta_windows` on an assembly
- Convert all outputs to TSV and bedGraph files
- Index all output files with `tabix`

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Dependency    | Old version | New version |
| ------------- | ----------- | ----------- |
| bgzip         |             | 1.11        |
| fasta_windows |             | 0.2.4       |
| MultiQC       |             | 1.13        |
| Python        |             | 3.8.3,3.9   |
| tabix         |             | 1.11        |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.

### Parameters

| Old parameter | New parameter        |
| ------------- | -------------------- |
|               | --input              |
|               | --fasta              |
|               | --window_size_info   |
|               | --selected_fw_output |

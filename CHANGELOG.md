# sanger-tol/sequencecomposition: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1.0 - [date]

### `Fixed`
- nf-core module updates to remove Anaconda references

### `Added`

## v1.0.0 - [2022-10-08]

Initial release of sanger-tol/sequencecomposition, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Run `fasta_windows` on an assembly
- Convert all outputs to TSV and bedGraph files
- Index all output files with `tabix`

### `Dependencies`

All dependencies are automatically fetched by Singularity.

- fasta_windows
- bgzip
- tabix
- python3

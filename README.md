# ![sanger-tol/sequencecomposition](docs/images/sanger-tol-sequencecomposition_logo.png)

[![GitHub Actions CI Status](https://github.com/sanger-tol/sequencecomposition/workflows/nf-core%20CI/badge.svg)](https://github.com/sanger-tol/sequencecomposition/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/sanger-tol/sequencecomposition/workflows/nf-core%20linting/badge.svg)](https://github.com/sanger-tol/sequencecomposition/actions?query=workflow%3A%22nf-core+linting%22)

[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.7155168-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.7155168)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.10.1-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=conda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Get help on Slack](http://img.shields.io/badge/slack-SangerTreeofLife%20%23pipelines-4A154B?labelColor=000000&logo=slack)](https://SangerTreeofLife.slack.com/channels/pipelines)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40sangertol-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/sangertol)
[![Watch on YouTube](http://img.shields.io/badge/youtube-tree--of--life-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/channel/UCFeDpvjU58SA9V0ycRXejhA)

## Introduction

**sanger-tol/sequencecomposition** is a bioinformatics analysis pipeline that extracts statistics from a genome about its sequence composition.

The pipeline takes an assembly Fasta file (possibly compressed), runs `fasta_windows` on it, and transforms the outputs into files more practical for downstream use.

Steps involved:

- Run `fasta_windows` on the assembly Fasta file.
- Extract single-statistics bedGraph files from the multi-statistics TSV
  files `fasta_windows` outputs.
- Compress and index all bedGraph and TSV files with `bgzip` and `tabix`.

## Usage

> **Note**
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how
> to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline)
> with `-profile test` before running the workflow on actual data.

The easiest is to provide the path of the Fasta file to analyse like this:

```console
nextflow run sanger-tol/sequencecomposition --fasta /path/to/genome.fa
```

> **Warning:**
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those
> provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

The pipeline also supports bulk downloads through a sample-sheet.
More information about this mode on our [pipeline website](https://pipelines.tol.sanger.ac.uk/sequencecomposition/usage).

## Credits

sanger-tol/sequencecomposition was originally written by [Matthieu Muffato](https://github.com/muffato).

We thank the following people for their assistance in the development of this pipeline:

- [Priyanka Surana](https://github.com/priyanka-surana) for providing reviews.
- [Tyler Chafin](https://github.com/tkchafin) for updates.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#pipelines` channel](https://sangertreeoflife.slack.com/channels/pipelines). Please [create an issue](https://github.com/sanger-tol/sequencecomposition/issues/new/choose) on GitHub if you are not on the Sanger slack channel.

## Citations

If you use sanger-tol/sequencecomposition for your analysis, please cite it using the following doi: [10.5281/zenodo.7155168](https://doi.org/10.5281/zenodo.7155168)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

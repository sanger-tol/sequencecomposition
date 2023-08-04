#!/usr/bin/env python
# This script is modified from nf-core's default check_samplesheet.py


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import csv
import logging
import re
import sys
from collections import Counter
from pathlib import Path

logger = logging.getLogger()


class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
            validated and transformed row. The order of rows is maintained.

    """

    def __init__(
        self,
        dir_col="outdir",
        fasta_col="fasta",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.

        Args:
            dir_col (str): The name of the column that contains the species directory
                (default "outdir").
            fasta_col (str): The name of the column that contains the path to the
                Fasta (default "fasta").

        """
        super().__init__(**kwargs)
        self._dir_col = dir_col
        self._fasta_col = fasta_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_dir(row)
        self._validate_fasta(row)
        self._seen.add(row[self._fasta_col])
        self.modified.append(row)

    def _validate_dir(self, row):
        """Assert that the species directory is non-empty."""
        if not row[self._dir_col]:
            raise AssertionError("Species directory is required.")

    def validate_unique_assemblies(self):
        """
        Assert that the assembly parameters are unique.
        """
        if len(self._seen) != len(self.modified):
            raise AssertionError("The pair of species directories and assembly names must be unique.")

    def _validate_fasta(self, row):
        """Assert that the fasta path is not only white space."""
        if set(row[self._fasta_col]) == set(" "):
            raise AssertionError("Paths cannot only be whitespace.")


def read_head(handle, num_lines=10):
    """Read the specified number of lines from the current position in the file."""
    lines = []
    for idx, line in enumerate(handle):
        if idx == num_lines:
            break
        lines.append(line)
    return "".join(lines)


def sniff_format(handle):
    """
    Detect the tabular format.

    Args:
        handle (text file): A handle to a `text file`_ object. The read position is
        expected to be at the beginning (index 0).

    Returns:
        csv.Dialect: The detected tabular format.

    .. _text file:
        https://docs.python.org/3/glossary.html#term-text-file

    """
    peek = read_head(handle)
    handle.seek(0)
    sniffer = csv.Sniffer()
    dialect = sniffer.sniff(peek)
    return dialect


def check_samplesheet(file_in, file_out):
    """
    Check that the tabular samplesheet has the structure expected by the pipeline.

    Validate the general shape of the table, expected columns, and each row.

    Args:
        file_in (pathlib.Path): The given tabular samplesheet. The format can be either
            CSV, TSV, or any other format automatically recognized by ``csv.Sniffer``.
        file_out (pathlib.Path): Where the validated and transformed samplesheet should
            be created; always in CSV format.

    Example:
        This function checks that the samplesheet follows the following structure::

            outdir,fasta
            Asterias_rubens/eAstRub1.3,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/902/459/465/GCA_902459465.3_eAstRub1.3/GCA_902459465.3_eAstRub1.3_genomic.fna.gz
            Osmia_bicornis/iOsmBic2.1,https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/907/164/935/GCA_907164935.1_iOsmBic2.1/GCA_907164935.1_iOsmBic2.1_genomic.fna.gz
    """
    required_columns = {
        "outdir",
        "fasta",
    }
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        # Validate the existence of the expected header columns.
        if not required_columns.issubset(reader.fieldnames):
            req_cols = ", ".join(required_columns)
            logger.critical(f"The sample sheet **must** contain these column headers: {req_cols}.")
            sys.exit(1)
        # Validate each row.
        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)
        checker.validate_unique_assemblies()
    header = list(reader.fieldnames)
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py samplesheet.csv samplesheet.valid.csv",
    )
    parser.add_argument(
        "file_in",
        metavar="FILE_IN",
        type=Path,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "file_out",
        metavar="FILE_OUT",
        type=Path,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.file_in.is_file():
        logger.error(f"The given input file {args.file_in} was not found!")
        sys.exit(2)
    args.file_out.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.file_in, args.file_out)


if __name__ == "__main__":
    sys.exit(main())

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
        dir_col="species_dir",
        name_col="assembly_name",
        accession_col="assembly_accession",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.

        Args:
            dir_col (str): The name of the column that contains the species directory
                (default "species_dir").
            name_col (str): The name of the column that contains the assembly name
                (default "assembly_name").
            accession_col (str): The name of the column that contains the accession
                number (default "assembly_accession").

        """
        super().__init__(**kwargs)
        self._dir_col = dir_col
        self._name_col = name_col
        self._accession_col = accession_col
        self._seen = set()
        self.modified = []
        self._regex_accession = re.compile(r"^GCA_[0-9]{9}\.[0-9]+$")

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_dir(row)
        self._validate_name(row)
        self._validate_accession(row)
        self._seen.add((row[self._name_col], row[self._dir_col]))
        self.modified.append(row)

    def _validate_dir(self, row):
        """Assert that the species directory is non-empty."""
        if not row[self._dir_col]:
            raise AssertionError("Species directory is required.")

    def _validate_accession(self, row):
        """Assert that the accession number exists and matches the expected nomenclature."""
        if (
            self._accession_col in row
            and row[self._accession_col]
            and not self._regex_accession.match(row[self._accession_col])
        ):
            raise AssertionError(
                "Accession numbers must match %s." % self._regex_accession
            )

    def _validate_name(self, row):
        """Assert that the assembly name is non-empty and has no space."""
        if not row[self._name_col]:
            raise AssertionError("Assembly name is required.")
        if " " in row[self._name_col]:
            raise AssertionError("Accession names must not contain whitespace.")

    def validate_unique_assemblies(self):
        """
        Assert that the assembly parameters are unique.
        """
        if len(self._seen) != len(self.modified):
            raise AssertionError(
                "The pair of species directories and assembly names must be unique."
            )


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
    # if not sniffer.has_header(peek):
    #     logger.critical(f"The given sample sheet does not appear to contain a header.")
    #     sys.exit(1)
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

            species_dir,assembly_name
            darwin/data/fungi/Laetiporus_sulphureus,gfLaeSulp1.1
            darwin/data/mammals/Meles_meles,mMelMel3.2_paternal_haplotype
    """
    required_columns = {
        "species_dir",
        "assembly_name",
    }
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        # Validate the existence of the expected header columns.
        if not required_columns.issubset(reader.fieldnames):
            logger.critical(
                f"The sample sheet **must** contain the column headers: {', '.join(required_columns)}."
            )
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

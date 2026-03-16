#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

DATA_HEADER = (
    "WITH data (wikidata_id, name, type, country_iso, parent_wikidata_id, "
    "telephone_country_code, local_dialing_code, latitude, longitude) AS ("
)
VALUES_HEADER = "    VALUES"
UPSERT_HEADER = "), upsert AS ("
STAGE_COLUMNS = [
    "wikidata_id",
    "name",
    "type",
    "country_iso",
    "parent_wikidata_id",
    "telephone_country_code",
    "local_dialing_code",
    "latitude",
    "longitude",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Stream rows from 18-load-territory-from-wikidata.sql as CSV."
    )
    parser.add_argument(
        "--source",
        type=Path,
        required=True,
        help="Path to the large 18-load-territory-from-wikidata.sql file.",
    )
    return parser.parse_args()


def iter_rows(source: Path):
    in_values = False
    saw_data_header = False
    saw_values_header = False

    with source.open("r", encoding="utf-8") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\n")
            if not saw_data_header:
                if line == DATA_HEADER:
                    saw_data_header = True
                continue

            if not saw_values_header:
                if line == VALUES_HEADER:
                    saw_values_header = True
                    in_values = True
                continue

            if in_values:
                if line == UPSERT_HEADER:
                    return
                row = line.strip()
                if not row:
                    continue
                yield line_number, row.removesuffix(",")

    raise RuntimeError(f"Did not find the end of the VALUES block in {source}.")


def parse_sql_tuple(row: str, line_number: int) -> list[str]:
    if not row.startswith("(") or not row.endswith(")"):
        raise RuntimeError(f"Invalid tuple format at line {line_number}: {row[:120]}")

    values: list[str] = []
    token: list[str] = []
    in_string = False
    was_quoted = False
    i = 1
    limit = len(row) - 1

    while i < limit:
        char = row[i]
        if in_string:
            if char == "'":
                if i + 1 < limit and row[i + 1] == "'":
                    token.append("'")
                    i += 2
                    continue
                in_string = False
                i += 1
                continue

            token.append(char)
            i += 1
            continue

        if char == "'":
            in_string = True
            was_quoted = True
            i += 1
            continue

        if char == ",":
            raw_value = "".join(token).strip()
            values.append("" if (not was_quoted and raw_value == "NULL") else raw_value)
            token = []
            was_quoted = False
            i += 1
            continue

        token.append(char)
        i += 1

    raw_value = "".join(token).strip()
    values.append("" if (not was_quoted and raw_value == "NULL") else raw_value)

    if len(values) != len(STAGE_COLUMNS):
        raise RuntimeError(
            f"Expected {len(STAGE_COLUMNS)} values at line {line_number}, found {len(values)}."
        )

    return values


def main() -> None:
    args = parse_args()
    source = args.source.resolve()

    if not source.is_file():
        raise RuntimeError(f"Source SQL file does not exist: {source}")

    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(STAGE_COLUMNS)
    for line_number, row in iter_rows(source):
        writer.writerow(parse_sql_tuple(row, line_number))


if __name__ == "__main__":
    main()

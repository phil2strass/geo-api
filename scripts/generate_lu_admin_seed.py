#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import sys
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

from stream_territory_wikidata_sql import iter_rows, parse_sql_tuple


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "lu_admin_seed.tsv"
DEFAULT_SOURCE_CSV = (
    "https://download.data.public.lu/resources/"
    "limites-administratives-du-grand-duche-de-luxembourg/20240709-164127/"
    "commune-canton-district-circonscription-arrondissements.csv"
)
TERRITORY_SQL = ROOT / "liquibase/changelog/18-load-territory-from-wikidata.sql"
EXPECTED_COUNTS = {
    "canton": 12,
    "municipality": 100,
}
MUNICIPALITY_NAME_OVERRIDES = {
    "Redange/Attert": "Redange-sur-Attert",
}
MUNICIPALITY_QID_OVERRIDES = {
    # Prefer the long-standing territorial item over the duplicate generic municipality item.
    "Remich": "Q734284",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Luxembourg administrative seed used by "
            "sync_admin_territory.sh from the official commune/canton CSV and the "
            "versioned territory snapshot."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--source-csv",
        default=DEFAULT_SOURCE_CSV,
        help="Official Luxembourg CSV URL or local path.",
    )
    parser.add_argument(
        "--territory-sql",
        type=Path,
        default=TERRITORY_SQL,
        help=f"Path to 18-load-territory-from-wikidata.sql (default: {TERRITORY_SQL})",
    )
    return parser.parse_args()


def fetch_text(source_csv: str) -> str:
    path = Path(source_csv)
    if path.is_file():
        return path.read_text(encoding="utf-8-sig")

    request = urllib.request.Request(
        source_csv,
        headers={"Accept": "text/csv", "User-Agent": "geo-api-lu-admin-seed/1.0"},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8-sig")


def load_official_rows(source_csv: str) -> tuple[list[dict[str, str]], dict[str, str]]:
    csv_text = fetch_text(source_csv)
    municipalities = list(csv.DictReader(io.StringIO(csv_text)))
    municipality_count = len(municipalities)
    if municipality_count != EXPECTED_COUNTS["municipality"]:
        raise RuntimeError(
            f"Unexpected Luxembourg municipality count: {municipality_count} != "
            f"{EXPECTED_COUNTS['municipality']}"
        )

    prefixes_by_canton: dict[str, set[str]] = defaultdict(set)
    for row in municipalities:
        prefixes_by_canton[row["CANTON"]].add(row["CODE_LAU2"][:2])

    if len(prefixes_by_canton) != EXPECTED_COUNTS["canton"]:
        raise RuntimeError(
            f"Unexpected Luxembourg canton count: {len(prefixes_by_canton)} != "
            f"{EXPECTED_COUNTS['canton']}"
        )

    canton_code_by_name: dict[str, str] = {}
    for canton_name, prefixes in prefixes_by_canton.items():
        if len(prefixes) != 1:
            raise RuntimeError(
                f"Expected exactly one LAU2 prefix for canton {canton_name}, got {sorted(prefixes)!r}"
            )
        canton_code_by_name[canton_name] = next(iter(prefixes))

    return municipalities, canton_code_by_name


def load_luxembourg_territory_index(territory_sql: Path) -> dict[tuple[str, str], list[str]]:
    if not territory_sql.is_file():
        raise FileNotFoundError(f"Missing territory snapshot SQL file: {territory_sql}")

    index: dict[tuple[str, str], list[str]] = defaultdict(list)
    for line_number, row in iter_rows(territory_sql):
        if ", 'LU'," not in row:
            continue
        parsed = parse_sql_tuple(row, line_number)
        wikidata_id, name, type_code, country_iso = parsed[:4]
        index[(type_code, name)].append(wikidata_id)
    return index


def resolve_unique(
    index: dict[tuple[str, str], list[str]],
    *,
    type_code: str,
    name: str,
) -> str:
    candidates = index.get((type_code, name), [])
    if len(candidates) != 1:
        raise RuntimeError(
            f"Expected exactly one territory match for Luxembourg {type_code} {name!r}, "
            f"got {candidates!r}"
        )
    return candidates[0]


def build_seed_rows(
    municipalities: list[dict[str, str]],
    canton_code_by_name: dict[str, str],
    territory_index: dict[tuple[str, str], list[str]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []

    for canton_name, canton_code in sorted(canton_code_by_name.items(), key=lambda item: item[1]):
        seed_rows.append(
            {
                "level_code": "canton",
                "admin_code": canton_code,
                "display_name": canton_name,
                "territory_wikidata_id": resolve_unique(
                    territory_index,
                    type_code="region",
                    name=f"Canton of {canton_name}",
                ),
                "parent_level_code": "",
                "parent_admin_code": "",
                "source": "seed.lu_admin_canton",
            }
        )

    for row in sorted(municipalities, key=lambda item: item["CODE_LAU2"]):
        official_name = row["COMMUNE"]
        territory_name = MUNICIPALITY_NAME_OVERRIDES.get(official_name, official_name)
        territory_wikidata_id = MUNICIPALITY_QID_OVERRIDES.get(official_name)
        if territory_wikidata_id is None:
            territory_wikidata_id = resolve_unique(
                territory_index,
                type_code="municipality",
                name=territory_name,
            )
        seed_rows.append(
            {
                "level_code": "municipality",
                "admin_code": row["CODE_LAU2"],
                "display_name": official_name,
                "territory_wikidata_id": territory_wikidata_id,
                "parent_level_code": "canton",
                "parent_admin_code": canton_code_by_name[row["CANTON"]],
                "source": "seed.lu_admin_municipality",
            }
        )

    counts = Counter(seed_row["level_code"] for seed_row in seed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Luxembourg seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")
    return seed_rows


def write_seed(rows: list[dict[str, str]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "level_code",
                "admin_code",
                "display_name",
                "territory_wikidata_id",
                "parent_level_code",
                "parent_admin_code",
                "source",
            ],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    municipalities, canton_code_by_name = load_official_rows(args.source_csv)
    territory_index = load_luxembourg_territory_index(args.territory_sql)
    seed_rows = build_seed_rows(municipalities, canton_code_by_name, territory_index)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Luxembourg administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("GEO_API_ROOT", str(SCRIPT_DIR.parent))).resolve()
COUNTRIES_SQL = ROOT / "liquibase/changelog/2-load-countries.sql"
TERRITORY_SQL = ROOT / "liquibase/changelog/18-load-territory-from-wikidata.sql"
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/26-load-country-admin-levels.sql"

COUNTRY_RE = re.compile(r"\(\d+,\s*'((?:[^']|'')+)',\s*'([A-Z]{2})',")
TERRITORY_RE = re.compile(
    r"^\s*\('(?:[^']|'')*',\s*'(?:[^']|'')*',\s*'([^']+)',\s*'([A-Z]{2})',"
)

# Keep the generated hierarchy to current administrative types only.
# Historical/cultural regions are intentionally excluded, which keeps the
# generated output under the requested 10-level cap.
TYPE_ORDER = [
    "overseas_region",
    "autonomous_region",
    "region",
    "state",
    "province",
    "department",
    "county",
    "district",
    "municipality",
]
TYPE_LABELS = {
    "overseas_region": "Overseas Region",
    "autonomous_region": "Autonomous Region",
    "region": "Region",
    "state": "State",
    "province": "Province",
    "department": "Department",
    "county": "County",
    "district": "District",
    "municipality": "Municipality",
}
SKIP_COUNTRY_ISOS = {"FR"}
FALLBACK_TYPES_BY_ISO = {
    # The current territory snapshot has no rows for CI, but the user asked
    # for all countries to be present in Liquibase.
    "CI": ["region"],
}


def parse_countries(path: Path) -> list[tuple[str, str]]:
    if not path.exists():
        raise FileNotFoundError(
            f"Missing input SQL file: {path}. Set GEO_API_ROOT to the repository path if needed."
        )

    text = path.read_text(encoding="utf-8")
    countries = [(iso, name.replace("''", "'")) for name, iso in COUNTRY_RE.findall(text)]
    if not countries:
        raise ValueError(f"No countries parsed from {path}.")
    return sorted(countries, key=lambda row: row[0])


def collect_country_types(path: Path) -> dict[str, set[str]]:
    if not path.exists():
        raise FileNotFoundError(
            f"Missing input SQL file: {path}. Generate the territory snapshot first."
        )

    valid_types = set(TYPE_ORDER)
    country_types: dict[str, set[str]] = defaultdict(set)

    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            match = TERRITORY_RE.match(line)
            if not match:
                continue
            type_code, country_iso = match.groups()
            if type_code not in valid_types:
                continue
            country_types[country_iso].add(type_code)

    return country_types


def build_seed_rows() -> list[tuple[str, int, str, str, str, str | None]]:
    countries = parse_countries(COUNTRIES_SQL)
    country_types = collect_country_types(TERRITORY_SQL)

    seed_rows: list[tuple[str, int, str, str, str, str | None]] = []
    for iso_code, _country_name in countries:
        if iso_code in SKIP_COUNTRY_ISOS:
            continue

        present_types = [
            type_code
            for type_code in TYPE_ORDER
            if type_code in country_types.get(iso_code, set())
        ]
        if not present_types:
            present_types = FALLBACK_TYPES_BY_ISO.get(iso_code, ["region"])

        parent_code: str | None = None
        for level_number, type_code in enumerate(present_types, start=1):
            seed_rows.append(
                (
                    iso_code,
                    level_number,
                    type_code,
                    TYPE_LABELS[type_code],
                    type_code,
                    parent_code,
                )
            )
            parent_code = type_code

    return seed_rows


def sql_literal(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def render_sql(rows: list[tuple[str, int, str, str, str, str | None]]) -> str:
    if not rows:
        raise ValueError("No admin-level rows generated.")

    values_sql = ",\n".join(
        "        ({country_iso}, {level_number}, {code}, {label}, {default_type}, {parent_code})".format(
            country_iso=sql_literal(country_iso),
            level_number=level_number,
            code=sql_literal(code),
            label=sql_literal(label),
            default_type=sql_literal(default_type),
            parent_code=sql_literal(parent_code),
        )
        for country_iso, level_number, code, label, default_type, parent_code in rows
    )

    parent_rows = [row for row in rows if row[-1] is not None]
    parent_values_sql = ",\n".join(
        "        ({country_iso}, {child_code}, {parent_code})".format(
            country_iso=sql_literal(country_iso),
            child_code=sql_literal(code),
            parent_code=sql_literal(parent_code),
        )
        for country_iso, _level_number, code, _label, _default_type, parent_code in parent_rows
    )

    sql = f"""--liquibase formatted sql

--changeset codex:26-load-country-admin-levels dbms:postgresql
--comment Seed inferred administrative level definitions for all countries except France from the normalized territory snapshot.

WITH seed(country_iso, level_number, code, label, default_territory_type_code, parent_code) AS (
    VALUES
{values_sql}
),
country_seed AS (
    SELECT
        c.id AS country_id,
        s.level_number,
        s.code,
        s.label,
        s.default_territory_type_code
    FROM seed s
    JOIN country c ON c.iso_code = s.country_iso
)
INSERT INTO country_admin_level (
    country_id,
    level_number,
    code,
    label,
    default_territory_type_code,
    parent_level_id,
    is_current
)
SELECT
    cs.country_id,
    cs.level_number,
    cs.code,
    cs.label,
    cs.default_territory_type_code,
    NULL,
    TRUE
FROM country_seed cs
ON CONFLICT (country_id, code) DO UPDATE
SET
    level_number = EXCLUDED.level_number,
    label = EXCLUDED.label,
    default_territory_type_code = EXCLUDED.default_territory_type_code,
    parent_level_id = NULL,
    is_current = EXCLUDED.is_current;

"""

    if parent_rows:
        sql += f"""WITH parent_seed(country_iso, child_code, parent_code) AS (
    VALUES
{parent_values_sql}
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM parent_seed ps
JOIN country c ON c.iso_code = ps.country_iso
JOIN country_admin_level parent
    ON parent.country_id = c.id
   AND parent.code = ps.parent_code
WHERE child.country_id = c.id
  AND child.code = ps.child_code;
"""

    return sql


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for country_admin_level seed data."
    )
    parser.add_argument(
        "--out-file",
        type=Path,
        default=DEFAULT_OUT_SQL,
        help=f"Output SQL file (default: {DEFAULT_OUT_SQL})",
    )
    args = parser.parse_args()

    rows = build_seed_rows()
    sql = render_sql(rows)
    args.out_file.write_text(sql, encoding="utf-8")

    countries = sorted({row[0] for row in rows})
    print(
        f"Wrote {len(rows)} admin-level rows for {len(countries)} countries to {args.out_file}"
    )


if __name__ == "__main__":
    main()

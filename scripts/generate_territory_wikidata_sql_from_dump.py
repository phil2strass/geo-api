#!/usr/bin/env python3
from __future__ import annotations

import argparse
import bz2
import gzip
import json
import os
import re
from pathlib import Path
from typing import Iterable, Iterator

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("GEO_API_ROOT", str(SCRIPT_DIR.parent))).resolve()
COUNTRIES_SQL = ROOT / "liquibase/changelog/2-load-countries.sql"
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/18-load-territory-from-wikidata.sql"

TYPE_MAPPING = [
    ("federal state", "state"),
    ("province", "province"),
    ("region", "region"),
    ("department", "department"),
    ("county", "county"),
    ("district", "district"),
    ("municipality", "municipality"),
    ("autonomous region", "autonomous_region"),
    ("overseas department", "overseas_region"),
    ("overseas territory", "overseas_region"),
    ("historical region", "historical_region"),
    ("cultural region", "cultural_region"),
]

TYPE_PRIORITY = {
    "overseas_region": 1,
    "autonomous_region": 2,
    "state": 3,
    "province": 4,
    "department": 5,
    "county": 6,
    "district": 7,
    "municipality": 8,
    "region": 9,
    "historical_region": 10,
    "cultural_region": 11,
}

TYPE_MAP_BY_LABEL = dict(TYPE_MAPPING)


def parse_iso_codes() -> list[str]:
    if not COUNTRIES_SQL.exists():
        raise FileNotFoundError(
            f"Missing input SQL file: {COUNTRIES_SQL}. "
            "Set GEO_API_ROOT to the repository path if needed."
        )
    text = COUNTRIES_SQL.read_text(encoding="utf-8")
    return sorted(set(re.findall(r"\(\d+,\s*'[^']+',\s*'([A-Z]{2})'", text)))


def open_dump(path: Path):
    if path.suffix == ".bz2":
        return bz2.open(path, mode="rt", encoding="utf-8")
    if path.suffix == ".gz":
        return gzip.open(path, mode="rt", encoding="utf-8")
    return path.open(mode="rt", encoding="utf-8")


def iter_dump_entities(path: Path, progress_every: int, pass_name: str) -> Iterator[dict]:
    scanned = 0
    with open_dump(path) as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line:
                continue

            if line.startswith("["):
                line = line[1:].strip()
            if line.endswith("]"):
                line = line[:-1].strip()
            if line.endswith(","):
                line = line[:-1].strip()
            if not line:
                continue

            scanned += 1
            if progress_every > 0 and scanned % progress_every == 0:
                print(f"{pass_name}: scanned {scanned} entities...")

            try:
                payload = json.loads(line)
            except json.JSONDecodeError:
                continue

            if isinstance(payload, dict):
                yield payload


def claim_datavalues(entity: dict, property_id: str) -> Iterable[object]:
    claims = entity.get("claims", {}).get(property_id, [])
    for claim in claims:
        mainsnak = claim.get("mainsnak", {})
        if mainsnak.get("snaktype") != "value":
            continue
        datavalue = mainsnak.get("datavalue")
        if not isinstance(datavalue, dict):
            continue
        if "value" in datavalue:
            yield datavalue["value"]


def claim_item_ids(entity: dict, property_id: str) -> list[str]:
    out: list[str] = []
    for value in claim_datavalues(entity, property_id):
        if not isinstance(value, dict):
            continue
        raw_id = value.get("id")
        if isinstance(raw_id, str) and raw_id.startswith("Q"):
            out.append(raw_id)
            continue
        numeric_id = value.get("numeric-id")
        if isinstance(numeric_id, int):
            out.append(f"Q{numeric_id}")
    return out


def claim_string_values(entity: dict, property_id: str) -> list[str]:
    out: list[str] = []
    for value in claim_datavalues(entity, property_id):
        if isinstance(value, str):
            out.append(value)
    return out


def claim_first_point(entity: dict, property_id: str) -> tuple[float | None, float | None]:
    for value in claim_datavalues(entity, property_id):
        if not isinstance(value, dict):
            continue
        lat = value.get("latitude")
        lon = value.get("longitude")
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            return float(lat), float(lon)
    return None, None


def qid(entity: dict) -> str | None:
    entity_id = entity.get("id")
    if isinstance(entity_id, str) and entity_id.startswith("Q"):
        return entity_id
    return None


def en_label(entity: dict) -> str | None:
    labels = entity.get("labels", {})
    if not isinstance(labels, dict):
        return None
    en = labels.get("en")
    if not isinstance(en, dict):
        return None
    value = en.get("value")
    if isinstance(value, str) and value.strip():
        return value.strip()
    return None


def sql_string(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def sql_number(value: float | None) -> str:
    if value is None:
        return "NULL"
    return f"{value:.6f}"


def render_sql(rows: list[dict]) -> str:
    if not rows:
        raise RuntimeError("No territory rows were produced from the dump.")

    value_lines = []
    for row in rows:
        value_lines.append(
            "("
            + ", ".join(
                [
                    sql_string(row["qid"]),
                    sql_string(row["name"]),
                    sql_string(row["type"]),
                    sql_string(row["country_iso"]),
                    sql_string(row["parent_qid"]),
                    sql_number(row["lat"]),
                    sql_number(row["lon"]),
                ]
            )
            + ")"
        )

    return f"""--liquibase formatted sql
--changeset codex:18-load-territory-from-wikidata dbms:postgresql
--comment Load territory data from Wikidata dump (P17/P31/P131/P625) with mapped territory types.

WITH data (wikidata_id, name, type, country_iso, parent_wikidata_id, latitude, longitude) AS (
    VALUES
        {",\n        ".join(value_lines)}
), upsert AS (
    INSERT INTO territory (wikidata_id, name, type, country_id, parent_id, latitude, longitude)
    SELECT
        d.wikidata_id,
        d.name,
        d.type,
        c.id,
        NULL,
        d.latitude,
        d.longitude
    FROM data d
    JOIN country c ON c.iso_code = d.country_iso
    ON CONFLICT (wikidata_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        country_id = EXCLUDED.country_id,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude
)
UPDATE territory t
SET parent_id = p.id
FROM data d
JOIN territory p ON p.wikidata_id = d.parent_wikidata_id
WHERE t.wikidata_id = d.wikidata_id
  AND d.parent_wikidata_id IS NOT NULL
  AND t.parent_id IS DISTINCT FROM p.id;
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for territory import from a local Wikidata dump."
    )
    parser.add_argument(
        "--dump-file",
        required=True,
        help="Path to Wikidata entities dump (.json, .json.gz, .json.bz2).",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=str(DEFAULT_OUT_SQL),
        help=f"Output SQL file path (default: {DEFAULT_OUT_SQL}).",
    )
    parser.add_argument(
        "--only-iso",
        type=str,
        default="",
        help="Comma-separated ISO2 list to process only specific countries (example: AF,AE,FR).",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=200000,
        help="Progress log frequency in scanned entities (0 disables progress logs).",
    )
    args = parser.parse_args()

    dump_path = Path(args.dump_file).expanduser().resolve()
    if not dump_path.exists():
        raise FileNotFoundError(f"Dump file not found: {dump_path}")

    iso_codes = parse_iso_codes()
    if args.only_iso.strip():
        wanted = {x.strip().upper() for x in args.only_iso.split(",") if x.strip()}
        iso_codes = [iso for iso in iso_codes if iso in wanted]
        print(f"only-iso mode: {','.join(iso_codes)}")
    wanted_iso_set = set(iso_codes)
    if not wanted_iso_set:
        raise RuntimeError("No ISO code selected. Check --only-iso.")

    # Pass 1: resolve country QIDs from P297 and collect type QIDs from English labels.
    country_candidates: dict[str, set[str]] = {}
    type_qid_to_mapped: dict[str, str] = {}
    for entity in iter_dump_entities(dump_path, args.progress_every, pass_name="pass1"):
        entity_qid = qid(entity)
        if entity_qid is None:
            continue

        label = en_label(entity)
        if label:
            mapped = TYPE_MAP_BY_LABEL.get(label.lower())
            if mapped:
                type_qid_to_mapped[entity_qid] = mapped

        for iso in claim_string_values(entity, "P297"):
            iso_up = iso.upper()
            if iso_up not in wanted_iso_set:
                continue
            # Keep all entities for this ISO to avoid dropping territories when
            # multiple Wikidata items share the same P297 code.
            country_candidates.setdefault(iso_up, set()).add(entity_qid)

    country_qids_by_iso = {
        iso: sorted(country_candidates.get(iso, set()), key=lambda item: int(item[1:]))
        for iso in sorted(wanted_iso_set)
        if country_candidates.get(iso)
    }

    missing_iso = sorted(wanted_iso_set - set(country_qids_by_iso.keys()))
    if missing_iso:
        print(f"warning: no country QID found for ISO: {','.join(missing_iso)}")

    country_iso_by_qid: dict[str, str] = {}
    for iso, qids in country_qids_by_iso.items():
        for qid_value in qids:
            country_iso_by_qid[qid_value] = iso
    print(
        f"pass1 summary: iso_covered={len(country_qids_by_iso)}/{len(wanted_iso_set)} "
        f"country_qids={len(country_iso_by_qid)} type_qids={len(type_qid_to_mapped)}"
    )
    if not country_iso_by_qid:
        raise RuntimeError("No country QID found. Cannot continue.")

    # Pass 2: extract territory rows from country relation + mapped types.
    rows_by_qid: dict[str, dict] = {}
    skipped_no_type = 0
    for entity in iter_dump_entities(dump_path, args.progress_every, pass_name="pass2"):
        entity_qid = qid(entity)
        if entity_qid is None:
            continue

        p17_country_isos = sorted(
            {
                country_iso_by_qid[p17_qid]
                for p17_qid in claim_item_ids(entity, "P17")
                if p17_qid in country_iso_by_qid
            }
        )
        if not p17_country_isos:
            continue

        mapped_types = sorted(
            {
                type_qid_to_mapped[p31_qid]
                for p31_qid in claim_item_ids(entity, "P31")
                if p31_qid in type_qid_to_mapped
            },
            key=lambda type_code: TYPE_PRIORITY.get(type_code, 999),
        )
        if not mapped_types:
            skipped_no_type += 1
            continue

        parent_qid = None
        for parent in claim_item_ids(entity, "P131"):
            parent_qid = parent
            break
        lat, lon = claim_first_point(entity, "P625")

        rows_by_qid[entity_qid] = {
            "qid": entity_qid,
            "name": en_label(entity) or entity_qid,
            "type": mapped_types[0],
            "country_iso": p17_country_isos[0],
            "parent_qid": parent_qid,
            "lat": lat,
            "lon": lon,
        }

    rows = sorted(rows_by_qid.values(), key=lambda row: (row["country_iso"], row["name"], row["qid"]))
    sql = render_sql(rows)

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(sql, encoding="utf-8")

    print(f"territories kept: {len(rows)}")
    print(f"territories skipped (no mapped P31 type): {skipped_no_type}")
    print(f"wrote: {output_path}")


if __name__ == "__main__":
    main()

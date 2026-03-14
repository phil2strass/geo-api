#!/usr/bin/env python3
from __future__ import annotations

import argparse
import bz2
import gzip
import json
import os
import re
from pathlib import Path
from typing import Iterator

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("GEO_API_ROOT", str(SCRIPT_DIR.parent))).resolve()
COUNTRIES_SQL = ROOT / "liquibase/changelog/2-load-countries.sql"
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/24-load-territory-translations-from-wikidata.sql"

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

TYPE_MAP_BY_LABEL = dict(TYPE_MAPPING)

WDT = "http://www.wikidata.org/prop/direct/"
RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"
P17 = f"{WDT}P17"
P31 = f"{WDT}P31"
P297 = f"{WDT}P297"

TRIPLE_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)> <([^>]+)> (.+) \.$')
QOBJ_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)>$')
LIT_RE = re.compile(r'^"((?:[^"\\]|\\.)*)"(?:(@[A-Za-z0-9-]+)|\^\^<[^>]+>)?$')
LANG_BASE_RE = re.compile(r"^[a-z]{2,3}$")


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


def iter_triples(path: Path, progress_every: int, pass_name: str) -> Iterator[tuple[str, str, str]]:
    scanned = 0
    with open_dump(path) as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            scanned += 1
            if progress_every > 0 and scanned % progress_every == 0:
                print(f"{pass_name}: scanned {scanned} triples...")
            m = TRIPLE_RE.match(line)
            if not m:
                continue
            yield m.group(1), m.group(2), m.group(3)


def parse_literal(obj: str) -> tuple[str | None, str | None]:
    m = LIT_RE.match(obj)
    if not m:
        return None, None
    raw = m.group(1)
    lang = m.group(2)
    try:
        value = json.loads(f'"{raw}"')
    except json.JSONDecodeError:
        return None, None
    return value, (lang[1:].lower() if lang else None)


def parse_object_qid(obj: str) -> str | None:
    m = QOBJ_RE.match(obj)
    if not m:
        return None
    return m.group(1)


def normalize_lang_code(lang_tag: str | None) -> str | None:
    if not lang_tag:
        return None
    base = lang_tag.split("-", 1)[0].strip().lower()
    if not LANG_BASE_RE.match(base):
        return None
    return base


def qid_sort_key(qid: str) -> int:
    return int(qid[1:])


def sql_string(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def render_sql(rows: list[dict]) -> str:
    if not rows:
        raise RuntimeError("No territory translation rows were produced from the WDQS truthy dump.")

    value_lines = []
    for row in rows:
        value_lines.append(
            "("
            + ", ".join(
                [
                    sql_string(row["territory_wikidata_id"]),
                    sql_string(row["lang_code"]),
                    sql_string(row["name"]),
                    sql_string(row["source"]),
                ]
            )
            + ")"
        )

    values_sql = ",\n        ".join(value_lines)
    return f"""--liquibase formatted sql
--changeset codex:22-load-territory-translations-from-wikidata dbms:postgresql
--comment Load territory translated names from WDQS truthy dump labels (rdfs:label), filtered with P17/P31 mapping.

WITH data (territory_wikidata_id, lang_code, name, source) AS (
    VALUES
        {values_sql}
), lang_code_map AS (
    SELECT code, MIN(id) AS language_id
    FROM (
        SELECT lower(iso639_1) AS code, id
        FROM language
        WHERE iso639_1 IS NOT NULL
        UNION ALL
        SELECT lower(iso639_3) AS code, id
        FROM language
        WHERE iso639_3 IS NOT NULL
    ) l
    GROUP BY code
)
INSERT INTO territory_translation (territory_id, language_id, name, source)
SELECT
    t.id,
    lcm.language_id,
    d.name,
    d.source
FROM data d
JOIN territory t ON t.wikidata_id = d.territory_wikidata_id
JOIN lang_code_map lcm ON lcm.code = d.lang_code
ON CONFLICT (territory_id, language_id) DO UPDATE
SET
    name = EXCLUDED.name,
    source = EXCLUDED.source
WHERE territory_translation.source = 'seed.fallback.territory_defaults'
   OR territory_translation.source = EXCLUDED.source;
"""


def flush_subject(
    subject_qid: str | None,
    state: dict,
    rows_by_key: dict[tuple[str, str], dict],
    only_lang_set: set[str],
) -> tuple[int, str | None]:
    if subject_qid is None:
        return 0, None
    if not state["countries"]:
        return 0, "no_country"
    if not state["types"]:
        return 0, "no_type"
    if not state["labels"]:
        return 0, "no_label"

    added = 0
    for lang_code, label in state["labels"].items():
        if only_lang_set and lang_code not in only_lang_set:
            continue
        row_key = (subject_qid, lang_code)
        if row_key in rows_by_key:
            continue
        rows_by_key[row_key] = {
            "territory_wikidata_id": subject_qid,
            "lang_code": lang_code,
            "name": label,
            "source": "wikidata.truthy.rdfslabel.p17p31",
        }
        added += 1

    if added == 0:
        return 0, "lang_filtered"
    return added, None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for territory translations from WDQS truthy dump."
    )
    parser.add_argument(
        "--dump-file",
        required=True,
        help="Path to WDQS dump (.nt, .nt.gz, .nt.bz2), e.g. latest-truthy.nt.bz2.",
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
        "--only-lang",
        type=str,
        default="",
        help="Comma-separated base language codes (example: en,fr,de).",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=5_000_000,
        help="Progress log frequency in scanned triples (0 disables progress logs).",
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

    only_lang_set = set()
    if args.only_lang.strip():
        only_lang_set = {
            x.strip().lower().split("-", 1)[0]
            for x in args.only_lang.split(",")
            if x.strip()
        }
        print(f"only-lang mode: {','.join(sorted(only_lang_set))}")

    # Pass 1: map ISO2 -> country QIDs using P297 and collect mapped territory-type QIDs.
    country_qids_by_iso: dict[str, set[str]] = {}
    type_qid_to_mapped: dict[str, str] = {}
    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass1"):
        if predicate == P297:
            value, _ = parse_literal(obj)
            if isinstance(value, str):
                iso = value.upper()
                if iso in wanted_iso_set:
                    country_qids_by_iso.setdefault(iso, set()).add(subject_qid)
        elif predicate == RDFS_LABEL:
            value, lang = parse_literal(obj)
            if lang == "en" and isinstance(value, str):
                mapped = TYPE_MAP_BY_LABEL.get(value.lower())
                if mapped:
                    type_qid_to_mapped[subject_qid] = mapped

    missing_iso = sorted(wanted_iso_set - set(country_qids_by_iso.keys()))
    if missing_iso:
        print(f"warning: no country QID found for ISO: {','.join(missing_iso)}")

    country_iso_by_qid: dict[str, str] = {}
    for iso, qids in country_qids_by_iso.items():
        for qid in qids:
            country_iso_by_qid[qid] = iso

    print(
        f"pass1 summary: iso_covered={len(country_qids_by_iso)}/{len(wanted_iso_set)} "
        f"country_qids={len(country_iso_by_qid)} type_qids={len(type_qid_to_mapped)}"
    )
    if not country_iso_by_qid:
        raise RuntimeError("No country QID found. Cannot continue.")

    # Pass 2: keep entities matching P17+mapped P31 and emit all base-language labels.
    rows_by_key: dict[tuple[str, str], dict] = {}
    skipped_no_country = 0
    skipped_no_type = 0
    skipped_no_label = 0
    skipped_lang_filtered = 0

    current_qid: str | None = None
    current = {
        "countries": set(),
        "types": set(),
        "labels": {},
    }

    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass2"):
        if current_qid != subject_qid:
            _added, reason = flush_subject(current_qid, current, rows_by_key, only_lang_set)
            if reason == "no_country":
                skipped_no_country += 1
            elif reason == "no_type":
                skipped_no_type += 1
            elif reason == "no_label":
                skipped_no_label += 1
            elif reason == "lang_filtered":
                skipped_lang_filtered += 1

            current_qid = subject_qid
            current = {
                "countries": set(),
                "types": set(),
                "labels": {},
            }

        if predicate == P17:
            country_qid = parse_object_qid(obj)
            if country_qid and country_qid in country_iso_by_qid:
                current["countries"].add(country_iso_by_qid[country_qid])
        elif predicate == P31:
            type_qid = parse_object_qid(obj)
            if type_qid and type_qid in type_qid_to_mapped:
                current["types"].add(type_qid_to_mapped[type_qid])
        elif predicate == RDFS_LABEL:
            value, lang_tag = parse_literal(obj)
            if not isinstance(value, str):
                continue
            lang_code = normalize_lang_code(lang_tag)
            if not lang_code:
                continue
            if lang_code not in current["labels"]:
                current["labels"][lang_code] = value

    _added, reason = flush_subject(current_qid, current, rows_by_key, only_lang_set)
    if reason == "no_country":
        skipped_no_country += 1
    elif reason == "no_type":
        skipped_no_type += 1
    elif reason == "no_label":
        skipped_no_label += 1
    elif reason == "lang_filtered":
        skipped_lang_filtered += 1

    rows = sorted(
        rows_by_key.values(),
        key=lambda r: (qid_sort_key(r["territory_wikidata_id"]), r["lang_code"]),
    )
    sql = render_sql(rows)

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(sql, encoding="utf-8")

    territory_qids = {r["territory_wikidata_id"] for r in rows}
    print(f"territories kept: {len(territory_qids)}")
    print(f"translation rows kept: {len(rows)}")
    print(f"territories skipped (no P17 country match): {skipped_no_country}")
    print(f"territories skipped (no mapped P31 type): {skipped_no_type}")
    print(f"territories skipped (no label): {skipped_no_label}")
    if only_lang_set:
        print(f"territories skipped (labels filtered by --only-lang): {skipped_lang_filtered}")
    print(f"wrote: {output_path}")


if __name__ == "__main__":
    main()

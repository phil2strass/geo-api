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
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/20-load-country-translations-from-wikidata.sql"

WDT = "http://www.wikidata.org/prop/direct/"
RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"
P297 = f"{WDT}P297"
P1448 = f"{WDT}P1448"

TRIPLE_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)> <([^>]+)> (.+) \.$')
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
        raise RuntimeError("No country translation rows were produced from the WDQS truthy dump.")

    value_lines = []
    for row in rows:
        value_lines.append(
            "("
            + ", ".join(
                [
                    sql_string(row["country_iso2"]),
                    sql_string(row["lang_code"]),
                    sql_string(row["common_name"]),
                    sql_string(row["official_name"]),
                    sql_string(row["source"]),
                ]
            )
            + ")"
        )

    values_sql = ",\n        ".join(value_lines)
    return f"""--liquibase formatted sql
--changeset codex:20-load-country-translations-from-wikidata dbms:postgresql
--comment Load country translated names from WDQS truthy dump labels (rdfs:label + P1448 official names).

WITH data (country_iso2, lang_code, common_name, official_name, source) AS (
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
INSERT INTO country_translation (country_id, language_id, common_name, official_name, source)
SELECT
    c.id,
    lcm.language_id,
    d.common_name,
    COALESCE(NULLIF(d.official_name, ''), d.common_name),
    d.source
FROM data d
JOIN country c ON c.iso_code = d.country_iso2
JOIN lang_code_map lcm ON lcm.code = d.lang_code
ON CONFLICT (country_id, language_id) DO UPDATE
SET
    common_name = EXCLUDED.common_name,
    official_name = COALESCE(EXCLUDED.official_name, country_translation.official_name),
    source = EXCLUDED.source
WHERE country_translation.source = 'seed.fallback.country_defaults'
   OR country_translation.source = EXCLUDED.source;
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for country translations from WDQS truthy dump."
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

    # Pass 1: map ISO2 -> candidate country QIDs using P297.
    country_qids_by_iso: dict[str, set[str]] = {}
    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass1"):
        if predicate != P297:
            continue
        value, _ = parse_literal(obj)
        if not isinstance(value, str):
            continue
        iso = value.upper()
        if iso in wanted_iso_set:
            country_qids_by_iso.setdefault(iso, set()).add(subject_qid)

    missing_iso = sorted(wanted_iso_set - set(country_qids_by_iso.keys()))
    if missing_iso:
        print(f"warning: no country QID found for ISO: {','.join(missing_iso)}")

    candidate_qids: set[str] = set()
    for qids in country_qids_by_iso.values():
        candidate_qids.update(qids)

    print(
        f"pass1 summary: iso_covered={len(country_qids_by_iso)}/{len(wanted_iso_set)} "
        f"candidate_country_qids={len(candidate_qids)}"
    )
    if not candidate_qids:
        raise RuntimeError("No country QID found. Cannot continue.")

    # Pass 2: collect labels for candidate QIDs.
    label_by_qid_lang: dict[tuple[str, str], str] = {}
    official_by_qid_lang: dict[tuple[str, str], str] = {}
    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass2"):
        if subject_qid not in candidate_qids:
            continue
        if predicate != RDFS_LABEL and predicate != P1448:
            continue

        value, lang_tag = parse_literal(obj)
        if not isinstance(value, str):
            continue
        lang_code = normalize_lang_code(lang_tag)
        if not lang_code:
            continue
        if only_lang_set and lang_code not in only_lang_set:
            continue

        key = (subject_qid, lang_code)
        if predicate == RDFS_LABEL:
            if key not in label_by_qid_lang:
                label_by_qid_lang[key] = value
        elif key not in official_by_qid_lang:
            official_by_qid_lang[key] = value

    # Pick one QID per ISO using best translation coverage.
    chosen_qid_by_iso: dict[str, str] = {}
    for iso, qids in country_qids_by_iso.items():
        ranked = sorted(
            qids,
            key=lambda q: (
                -sum(1 for (qid, _lang) in label_by_qid_lang if qid == q),
                qid_sort_key(q),
            ),
        )
        if not ranked:
            continue
        chosen_qid_by_iso[iso] = ranked[0]
        if len(ranked) > 1:
            print(
                f"info: multiple country QIDs for ISO {iso}: "
                + ",".join(ranked[:3])
                + ("..." if len(ranked) > 3 else "")
                + f" (picked {ranked[0]})"
            )

    # Build final rows keyed by (iso, language code).
    rows_by_key: dict[tuple[str, str], dict] = {}
    for iso, qid in chosen_qid_by_iso.items():
        for (subject_qid, lang_code), common_name in label_by_qid_lang.items():
            if subject_qid != qid:
                continue
            row_key = (iso, lang_code)
            rows_by_key[row_key] = {
                "country_iso2": iso,
                "lang_code": lang_code,
                "common_name": common_name,
                "official_name": official_by_qid_lang.get((qid, lang_code)),
                "source": "wikidata.truthy.rdfslabel+p1448",
            }

    rows = sorted(
        rows_by_key.values(),
        key=lambda r: (r["country_iso2"], r["lang_code"], r["common_name"]),
    )
    sql = render_sql(rows)

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(sql, encoding="utf-8")

    print(f"countries selected: {len(chosen_qid_by_iso)}")
    print(f"translation rows kept: {len(rows)}")
    print(f"wrote: {output_path}")


if __name__ == "__main__":
    main()

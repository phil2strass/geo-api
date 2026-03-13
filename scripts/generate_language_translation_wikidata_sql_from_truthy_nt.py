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
COUNTRY_DETAILS_SQL = ROOT / "liquibase/changelog/4-load-country-details.sql"
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/22-load-language-translations-from-wikidata.sql"

WDT = "http://www.wikidata.org/prop/direct/"
RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"
P220 = f"{WDT}P220"

TRIPLE_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)> <([^>]+)> (.+) \.$')
LIT_RE = re.compile(r'^"((?:[^"\\]|\\.)*)"(?:(@[A-Za-z0-9-]+)|\^\^<[^>]+>)?$')
LANG_BASE_RE = re.compile(r"^[a-z]{2,3}$")


def parse_language_iso3_codes() -> list[str]:
    if not COUNTRY_DETAILS_SQL.exists():
        raise FileNotFoundError(
            f"Missing input SQL file: {COUNTRY_DETAILS_SQL}. "
            "Set GEO_API_ROOT to the repository path if needed."
        )
    text = COUNTRY_DETAILS_SQL.read_text(encoding="utf-8")
    codes: set[str] = set()
    for match in re.finditer(r"languages\s*=\s*'(\{[^']*\})'::jsonb", text):
        codes.update(code.lower() for code in re.findall(r'"([A-Za-z]{3})":"[^"]*"', match.group(1)))
    return sorted(codes)


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
        raise RuntimeError("No language translation rows were produced from the WDQS truthy dump.")

    value_lines = []
    for row in rows:
        value_lines.append(
            "("
            + ", ".join(
                [
                    sql_string(row["language_iso639_3"]),
                    sql_string(row["translation_lang_code"]),
                    sql_string(row["name"]),
                    sql_string(row["source"]),
                ]
            )
            + ")"
        )

    values_sql = ",\n        ".join(value_lines)
    return f"""--liquibase formatted sql
--changeset codex:22-load-language-translations-from-wikidata dbms:postgresql
--comment Load language translated names from WDQS truthy dump labels (rdfs:label).

WITH data (language_iso639_3, translation_lang_code, name, source) AS (
    VALUES
        {values_sql}
), translation_lang_code_map AS (
    SELECT code, MIN(id) AS language_id
    FROM (
        SELECT lower(iso639_1) AS code, id
        FROM language
        WHERE iso639_1 IS NOT NULL
        UNION ALL
        SELECT lower(iso639_2b) AS code, id
        FROM language
        WHERE iso639_2b IS NOT NULL
        UNION ALL
        SELECT lower(iso639_2t) AS code, id
        FROM language
        WHERE iso639_2t IS NOT NULL
        UNION ALL
        SELECT lower(iso639_3) AS code, id
        FROM language
        WHERE iso639_3 IS NOT NULL
    ) l
    GROUP BY code
)
INSERT INTO language_translation (language_id, translation_language_id, name, source)
SELECT
    src.id,
    tlcm.language_id,
    d.name,
    d.source
FROM data d
JOIN language src ON src.iso639_3 = d.language_iso639_3
JOIN translation_lang_code_map tlcm ON tlcm.code = d.translation_lang_code
ON CONFLICT (language_id, translation_language_id) DO UPDATE
SET
    name = EXCLUDED.name,
    source = EXCLUDED.source;
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for language translations from WDQS truthy dump."
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
        "--only-iso6393",
        type=str,
        default="",
        help="Comma-separated ISO 639-3 list to process only specific languages (example: fra,eng,deu).",
    )
    parser.add_argument(
        "--only-lang",
        type=str,
        default="",
        help="Comma-separated base language codes for translations (example: en,fr,de).",
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

    iso6393_codes = parse_language_iso3_codes()
    if args.only_iso6393.strip():
        wanted = {x.strip().lower() for x in args.only_iso6393.split(",") if x.strip()}
        iso6393_codes = [code for code in iso6393_codes if code in wanted]
        print(f"only-iso6393 mode: {','.join(iso6393_codes)}")
    wanted_iso6393_set = set(iso6393_codes)
    if not wanted_iso6393_set:
        raise RuntimeError("No ISO 639-3 code selected. Check --only-iso6393.")

    only_lang_set = set()
    if args.only_lang.strip():
        only_lang_set = {
            x.strip().lower().split("-", 1)[0]
            for x in args.only_lang.split(",")
            if x.strip()
        }
        print(f"only-lang mode: {','.join(sorted(only_lang_set))}")

    # Pass 1: map ISO 639-3 -> candidate language QIDs using P220.
    language_qids_by_iso6393: dict[str, set[str]] = {}
    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass1"):
        if predicate != P220:
            continue
        value, _ = parse_literal(obj)
        if not isinstance(value, str):
            continue
        iso6393 = value.lower()
        if iso6393 in wanted_iso6393_set:
            language_qids_by_iso6393.setdefault(iso6393, set()).add(subject_qid)

    missing_iso6393 = sorted(wanted_iso6393_set - set(language_qids_by_iso6393.keys()))
    if missing_iso6393:
        print(f"warning: no language QID found for ISO 639-3: {','.join(missing_iso6393)}")

    candidate_qids: set[str] = set()
    for qids in language_qids_by_iso6393.values():
        candidate_qids.update(qids)

    print(
        f"pass1 summary: iso6393_covered={len(language_qids_by_iso6393)}/{len(wanted_iso6393_set)} "
        f"candidate_language_qids={len(candidate_qids)}"
    )
    if not candidate_qids:
        raise RuntimeError("No language QID found. Cannot continue.")

    # Pass 2: collect labels for candidate QIDs.
    label_by_qid_lang: dict[tuple[str, str], str] = {}
    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass2"):
        if subject_qid not in candidate_qids or predicate != RDFS_LABEL:
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
        if key not in label_by_qid_lang:
            label_by_qid_lang[key] = value

    # Pick one QID per ISO 639-3 using best translation coverage.
    chosen_qid_by_iso6393: dict[str, str] = {}
    for iso6393, qids in language_qids_by_iso6393.items():
        ranked = sorted(
            qids,
            key=lambda q: (
                -sum(1 for (qid, _lang) in label_by_qid_lang if qid == q),
                qid_sort_key(q),
            ),
        )
        if not ranked:
            continue
        chosen_qid_by_iso6393[iso6393] = ranked[0]
        if len(ranked) > 1:
            print(
                f"info: multiple language QIDs for ISO 639-3 {iso6393}: "
                + ",".join(ranked[:3])
                + ("..." if len(ranked) > 3 else "")
                + f" (picked {ranked[0]})"
            )

    # Build final rows keyed by (source language, translation language).
    rows_by_key: dict[tuple[str, str], dict] = {}
    for iso6393, qid in chosen_qid_by_iso6393.items():
        for (subject_qid, lang_code), name in label_by_qid_lang.items():
            if subject_qid != qid:
                continue
            row_key = (iso6393, lang_code)
            rows_by_key[row_key] = {
                "language_iso639_3": iso6393,
                "translation_lang_code": lang_code,
                "name": name,
                "source": "wikidata.truthy.rdfslabel",
            }

    rows = sorted(
        rows_by_key.values(),
        key=lambda r: (r["language_iso639_3"], r["translation_lang_code"], r["name"]),
    )
    sql = render_sql(rows)

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(sql, encoding="utf-8")

    print(f"languages selected: {len(chosen_qid_by_iso6393)}")
    print(f"translation rows kept: {len(rows)}")
    print(f"wrote: {output_path}")


if __name__ == "__main__":
    main()

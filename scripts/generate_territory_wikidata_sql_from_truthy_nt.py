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
DEFAULT_OUT_SQL = ROOT / "liquibase/changelog/18-load-territory-from-wikidata.sql"

TYPE_MAPPING = [
    ("federal state", "state"),
    ("province", "province"),
    ("region", "region"),
    ("region of France", "overseas_region"),
    ("department", "department"),
    ("county", "county"),
    ("district", "district"),
    ("municipality", "municipality"),
    ("autonomous region", "autonomous_region"),
    ("overseas department", "overseas_region"),
    ("overseas department and region of France", "overseas_region"),
    ("overseas territory", "overseas_region"),
    ("historical region", "historical_region"),
    ("cultural region", "cultural_region"),
]

ATTACHED_COUNTRY_LABELS = {
    "AU": {
        "christmas island",
        "cocos (keeling) islands",
        "norfolk island",
    },
    "CN": {
        "hong kong",
        "macau",
    },
    "DK": {
        "faroe islands",
        "greenland",
    },
    "ES": {
        "balearic islands",
        "canary islands",
        "ceuta",
        "melilla",
        "plazas de soberania",
        "rota",
        "spanish north africa",
    },
    "FI": {
        "aland islands",
        "åland islands",
    },
    "FR": {
        "clipperton island",
        "french guiana",
        "french polynesia",
        "french southern and antarctic lands",
        "french southern territories",
        "guadeloupe",
        "martinique",
        "mayotte",
        "new caledonia",
        "réunion",
        "reunion",
        "saint barthélemy",
        "saint barthelemy",
        "saint martin",
        "saint pierre and miquelon",
        "saint-pierre and miquelon",
        "wallis and futuna",
    },
    "GB": {
        "akrotiri and dhekelia",
        "alderney",
        "anguilla",
        "bermuda",
        "british antarctic territory",
        "british indian ocean territory",
        "british virgin islands",
        "cayman islands",
        "falkland islands",
        "gibraltar",
        "guernsey",
        "isle of man",
        "jersey",
        "montserrat",
        "pitcairn islands",
        "saint helena, ascension and tristan da cunha",
        "sark",
        "south georgia and the south sandwich islands",
        "turks and caicos islands",
    },
    "NL": {
        "aruba",
        "bonaire",
        "caribbean netherlands",
        "curaçao",
        "curacao",
        "saba",
        "sint eustatius",
        "sint maarten",
        "saint martin (dutch part)",
    },
    "NO": {
        "bouvet island",
        "jan mayen",
        "svalbard",
    },
    "NZ": {
        "chatham islands",
        "cook islands",
        "niue",
        "tokelau",
    },
    "PT": {
        "azores",
        "azores islands",
        "madeira",
        "madeira islands",
    },
    "US": {
        "american samoa",
        "guam",
        "guantánamo bay",
        "guantanamo bay",
        "northern mariana islands",
        "puerto rico",
        "u.s. virgin islands",
        "united states virgin islands",
        "us virgin islands",
    },
}
ATTACHED_COUNTRY_TYPE_QIDS = {
    "GB": {"Q46395", "Q185086"},
}

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
PREFERRED_LABEL_LANGS = (
    "en",
    "fr",
    "de",
    "es",
    "pt",
    "it",
    "nl",
    "ca",
    "pl",
    "cs",
    "sv",
)
QID_LIKE_RE = re.compile(r"^Q[0-9]+$")

WD = "http://www.wikidata.org/entity/"
WDT = "http://www.wikidata.org/prop/direct/"
RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"

P17 = f"{WDT}P17"
P31 = f"{WDT}P31"
P279 = f"{WDT}P279"
P131 = f"{WDT}P131"
P297 = f"{WDT}P297"
P473 = f"{WDT}P473"
P474 = f"{WDT}P474"
P625 = f"{WDT}P625"

TRIPLE_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)> <([^>]+)> (.+) \.$')
QOBJ_RE = re.compile(r'^<http://www\.wikidata\.org/entity/(Q\d+)>$')
LIT_RE = re.compile(r'^"((?:[^"\\]|\\.)*)"(?:(@[A-Za-z0-9-]+)|\^\^<[^>]+>)?$')
WKT_POINT_RE = re.compile(r"Point\(([-0-9.]+)\s+([-0-9.]+)\)")


def label_rank(lang: str | None) -> tuple[int, str]:
    if lang in PREFERRED_LABEL_LANGS:
        return (PREFERRED_LABEL_LANGS.index(lang), lang or "")
    if lang:
        return (len(PREFERRED_LABEL_LANGS) + 1, lang)
    return (len(PREFERRED_LABEL_LANGS) + 2, "")


def choose_better_label(current: tuple[str, str | None] | None, candidate: tuple[str, str | None] | None) -> tuple[str, str | None] | None:
    if candidate is None:
        return current
    if current is None:
        return candidate
    if label_rank(candidate[1]) < label_rank(current[1]):
        return candidate
    return current


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


def parse_point_literal(value: str | None) -> tuple[float | None, float | None]:
    if not value:
        return None, None
    m = WKT_POINT_RE.search(value)
    if not m:
        return None, None
    lon = float(m.group(1))
    lat = float(m.group(2))
    return lat, lon


def sql_string(value: str | None) -> str:
    if value is None:
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def sql_number(value: float | None) -> str:
    if value is None:
        return "NULL"
    return f"{value:.6f}"


def normalize_code_list(values: list[str]) -> str | None:
    cleaned = sorted({value.strip() for value in values if value and value.strip()})
    if not cleaned:
        return None
    return ",".join(cleaned)


def merge_row(existing: dict | None, candidate: dict) -> dict:
    if existing is None:
        return candidate

    old_p = TYPE_PRIORITY.get(existing["type"], 999)
    new_p = TYPE_PRIORITY.get(candidate["type"], 999)
    if new_p < old_p:
        candidate["parent_qid"] = candidate["parent_qid"] or existing.get("parent_qid")
        candidate["telephone_country_code"] = normalize_code_list(
            [candidate.get("telephone_country_code"), existing.get("telephone_country_code")]
        )
        candidate["local_dialing_code"] = normalize_code_list(
            (candidate.get("local_dialing_code") or "").split(",")
            + (existing.get("local_dialing_code") or "").split(",")
        )
        candidate["lat"] = candidate["lat"] if candidate["lat"] is not None else existing.get("lat")
        candidate["lon"] = candidate["lon"] if candidate["lon"] is not None else existing.get("lon")
        if QID_LIKE_RE.fullmatch(candidate["name"] or "") and not QID_LIKE_RE.fullmatch(existing.get("name") or ""):
            candidate["name"] = existing.get("name")
        return candidate

    existing["parent_qid"] = existing.get("parent_qid") or candidate["parent_qid"]
    existing["telephone_country_code"] = normalize_code_list(
        [existing.get("telephone_country_code"), candidate.get("telephone_country_code")]
    )
    existing["local_dialing_code"] = normalize_code_list(
        (existing.get("local_dialing_code") or "").split(",")
        + (candidate.get("local_dialing_code") or "").split(",")
    )
    existing["lat"] = existing.get("lat") if existing.get("lat") is not None else candidate["lat"]
    existing["lon"] = existing.get("lon") if existing.get("lon") is not None else candidate["lon"]
    if QID_LIKE_RE.fullmatch(existing.get("name") or "") and not QID_LIKE_RE.fullmatch(candidate["name"] or ""):
        existing["name"] = candidate["name"]
    return existing


def resolve_type_code(
    qid: str,
    direct_type_map: dict[str, str],
    subclass_parents: dict[str, set[str]],
    cache: dict[str, str | None],
    trail: set[str] | None = None,
) -> str | None:
    if qid in cache:
        return cache[qid]

    direct = direct_type_map.get(qid)
    if direct is not None:
        cache[qid] = direct
        return direct

    if trail is None:
        trail = set()
    if qid in trail:
        cache[qid] = None
        return None

    next_trail = set(trail)
    next_trail.add(qid)
    best_type: str | None = None
    best_priority = 999
    for parent_qid in subclass_parents.get(qid, ()):
        parent_type = resolve_type_code(parent_qid, direct_type_map, subclass_parents, cache, next_trail)
        if parent_type is None:
            continue
        parent_priority = TYPE_PRIORITY.get(parent_type, 999)
        if parent_priority < best_priority:
            best_type = parent_type
            best_priority = parent_priority

    cache[qid] = best_type
    return best_type


def render_sql(rows: list[dict]) -> str:
    if not rows:
        raise RuntimeError("No territory rows were produced from the WDQS truthy dump.")

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
                    sql_string(row["telephone_country_code"]),
                    sql_string(row["local_dialing_code"]),
                    sql_number(row["lat"]),
                    sql_number(row["lon"]),
                ]
            )
            + ")"
        )

    values_sql = ",\n        ".join(value_lines)
    return f"""--liquibase formatted sql
--changeset codex:18-load-territory-from-wikidata dbms:postgresql
--comment Load territory data from WDQS truthy dump (P17/P31/P131/P474/P473/P625) with mapped territory types.

WITH data (wikidata_id, name, type, country_iso, parent_wikidata_id, telephone_country_code, local_dialing_code, latitude, longitude) AS (
    VALUES
        {values_sql}
), upsert AS (
    INSERT INTO territory (wikidata_id, name, type, country_id, parent_id, telephone_country_code, local_dialing_code, latitude, longitude)
    SELECT
        d.wikidata_id,
        d.name,
        d.type,
        c.id,
        NULL,
        d.telephone_country_code,
        d.local_dialing_code,
        d.latitude,
        d.longitude
    FROM data d
    JOIN country c ON c.iso_code = d.country_iso
    ON CONFLICT (wikidata_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        country_id = EXCLUDED.country_id,
        telephone_country_code = EXCLUDED.telephone_country_code,
        local_dialing_code = EXCLUDED.local_dialing_code,
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


def flush_subject(
    subject_qid: str | None,
    state: dict,
    rows_by_qid: dict[str, dict],
) -> None:
    if subject_qid is None:
        return
    if not state["countries"] or not state["types"]:
        return

    chosen_type = sorted(state["types"], key=lambda t: TYPE_PRIORITY.get(t, 999))[0]
    chosen_country_iso = sorted(state["countries"])[0]
    chosen_label = state["label"][0] if state["label"] else None
    candidate = {
        "qid": subject_qid,
        "name": chosen_label or subject_qid,
        "type": chosen_type,
        "country_iso": chosen_country_iso,
        "parent_qid": state["parent_qid"],
        "telephone_country_code": normalize_code_list(state["telephone_country_codes"]),
        "local_dialing_code": normalize_code_list(state["local_dialing_codes"]),
        "lat": state["lat"],
        "lon": state["lon"],
    }
    rows_by_qid[subject_qid] = merge_row(rows_by_qid.get(subject_qid), candidate)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Liquibase SQL for territory import from WDQS truthy dump."
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

    # Pass 1: gather country QIDs and resolve territory types from labels plus subclass chains.
    country_qids_by_iso: dict[str, set[str]] = {}
    direct_type_map: dict[str, str] = {}
    subclass_parents: dict[str, set[str]] = {}
    attached_alias_qids: dict[str, set[str]] = {}

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
                    direct_type_map[subject_qid] = mapped
                label_lc = value.lower()
                for iso in wanted_iso_set:
                    if label_lc in ATTACHED_COUNTRY_LABELS.get(iso, ()):
                        attached_alias_qids.setdefault(iso, set()).add(subject_qid)
        elif predicate == P279:
            parent_qid = parse_object_qid(obj)
            if parent_qid:
                subclass_parents.setdefault(subject_qid, set()).add(parent_qid)
        elif predicate == P31:
            type_qid = parse_object_qid(obj)
            if type_qid:
                for iso in wanted_iso_set:
                    if type_qid in ATTACHED_COUNTRY_TYPE_QIDS.get(iso, set()):
                        attached_alias_qids.setdefault(iso, set()).add(subject_qid)

    for iso, qids in attached_alias_qids.items():
        country_qids_by_iso.setdefault(iso, set()).update(qids)

    type_qid_to_mapped: dict[str, str] = {}
    type_resolution_cache: dict[str, str | None] = {}
    for type_qid in set(direct_type_map) | set(subclass_parents):
        mapped = resolve_type_code(
            type_qid,
            direct_type_map,
            subclass_parents,
            type_resolution_cache,
        )
        if mapped is not None:
            type_qid_to_mapped[type_qid] = mapped

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

    # Pass 2: stream triples and build territory rows.
    rows_by_qid: dict[str, dict] = {}
    skipped_no_type = 0

    current_qid: str | None = None
    current = {
        "label": None,
        "countries": set(),
        "types": set(),
        "parent_qid": None,
        "telephone_country_codes": [],
        "local_dialing_codes": [],
        "lat": None,
        "lon": None,
    }

    for subject_qid, predicate, obj in iter_triples(dump_path, args.progress_every, pass_name="pass2"):
        if current_qid != subject_qid:
            flush_subject(current_qid, current, rows_by_qid)
            if current_qid is not None and current["countries"] and not current["types"]:
                skipped_no_type += 1

            current_qid = subject_qid
            current = {
                "label": None,
                "countries": set(),
                "types": set(),
                "parent_qid": None,
                "telephone_country_codes": [],
                "local_dialing_codes": [],
                "lat": None,
                "lon": None,
            }

        if predicate == RDFS_LABEL:
            value, lang = parse_literal(obj)
            if isinstance(value, str):
                value = value.strip()
                if value and not QID_LIKE_RE.fullmatch(value):
                    current["label"] = choose_better_label(current["label"], (value, lang))
        elif predicate == P17:
            country_qid = parse_object_qid(obj)
            if country_qid and country_qid in country_iso_by_qid:
                current["countries"].add(country_iso_by_qid[country_qid])
        elif predicate == P31:
            type_qid = parse_object_qid(obj)
            if type_qid and type_qid in type_qid_to_mapped:
                current["types"].add(type_qid_to_mapped[type_qid])
        elif predicate == P131:
            if current["parent_qid"] is None:
                parent_qid = parse_object_qid(obj)
                if parent_qid:
                    current["parent_qid"] = parent_qid
        elif predicate == P474:
            value, _ = parse_literal(obj)
            if isinstance(value, str):
                current["telephone_country_codes"].append(value)
        elif predicate == P473:
            value, _ = parse_literal(obj)
            if isinstance(value, str):
                current["local_dialing_codes"].append(value)
        elif predicate == P625:
            if current["lat"] is None or current["lon"] is None:
                point_literal, _ = parse_literal(obj)
                lat, lon = parse_point_literal(point_literal)
                if lat is not None and lon is not None:
                    current["lat"] = lat
                    current["lon"] = lon

    flush_subject(current_qid, current, rows_by_qid)
    if current_qid is not None and current["countries"] and not current["types"]:
        skipped_no_type += 1

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

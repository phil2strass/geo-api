#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from stream_territory_wikidata_sql import iter_rows, parse_sql_tuple


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "gb_electoral_ward_division_seed.tsv"
DEFAULT_LAD_SEED_PATH = SCRIPT_DIR / "data" / "gb_local_authority_district_seed.tsv"
DEFAULT_WARD_LOOKUP_URL = (
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/"
    "WD25_LAD25_UK_LU_v2/FeatureServer/0/query"
)
TERRITORY_SQL = ROOT / "liquibase/changelog" / "18-load-territory-from-wikidata.sql"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-gb-ward-seed/1.0 (local maintenance script)"
NORMALIZE_PATTERN = re.compile(r"[^0-9a-z]+")
NAME_SUFFIXES = (
    "electoralward",
    "electoraldivision",
    "ward",
    "division",
)
MANUAL_QID_OVERRIDES: dict[str, str] = {}


@dataclass(frozen=True)
class TerritorySnapshotRow:
    wikidata_id: str
    name: str
    type_code: str
    country_iso: str
    parent_wikidata_id: str


@dataclass(frozen=True)
class WikidataMatch:
    qid: str
    label: str
    description: str
    instance_of_label: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated United Kingdom electoral ward/division seed used by "
            "sync_admin_territory.sh from the official ONS 2025 ward-to-LAD lookup, "
            "Wikidata GSS code mappings and the versioned territory snapshot."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--ward-lookup-url",
        default=DEFAULT_WARD_LOOKUP_URL,
        help="Official ONS ward-to-LAD ArcGIS query endpoint.",
    )
    parser.add_argument(
        "--lad-seed",
        type=Path,
        default=DEFAULT_LAD_SEED_PATH,
        help=f"Path to gb_local_authority_district_seed.tsv (default: {DEFAULT_LAD_SEED_PATH})",
    )
    parser.add_argument(
        "--territory-sql",
        type=Path,
        default=TERRITORY_SQL,
        help=f"Path to 18-load-territory-from-wikidata.sql (default: {TERRITORY_SQL})",
    )
    parser.add_argument(
        "--page-size",
        type=int,
        default=2000,
        help="Number of ONS rows to request per page (default: 2000).",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=80,
        help="Number of ward codes per Wikidata SPARQL request (default: 80).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.25,
        help="Delay between Wikidata requests (default: 0.25).",
    )
    return parser.parse_args()


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": WIKIDATA_USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        payload = json.loads(response.read().decode("utf-8"))
    if "error" in payload:
        raise RuntimeError(f"ArcGIS request failed: {payload['error']}")
    return payload


def fetch_csv(url: str) -> list[dict[str, str]]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "text/csv",
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return list(csv.DictReader(io.StringIO(response.read().decode("utf-8"))))


def normalize_name(value: str) -> str:
    return NORMALIZE_PATTERN.sub(
        "",
        value.casefold()
        .replace("’", "'")
        .replace("‘", "'")
        .replace("&", " and ")
        .strip(),
    )


def comparable_names(value: str) -> set[str]:
    normalized = normalize_name(value)
    variants = {normalized}
    for suffix in NAME_SUFFIXES:
        if normalized.endswith(suffix) and len(normalized) > len(suffix):
            variants.add(normalized[: -len(suffix)])
    return {variant for variant in variants if variant}


def load_ward_rows(ward_lookup_url: str, *, page_size: int) -> list[dict[str, str]]:
    deduped: dict[str, dict[str, str]] = {}
    count_url = ward_lookup_url + "?" + urllib.parse.urlencode(
        {
            "where": "1=1",
            "returnCountOnly": "true",
            "f": "json",
        }
    )
    expected_count = fetch_json(count_url)["count"]
    offset = 0

    while offset < expected_count:
        query_url = ward_lookup_url + "?" + urllib.parse.urlencode(
            {
                "where": "1=1",
                "outFields": "WD25CD,WD25NM,LAD25CD,LAD25NM",
                "returnGeometry": "false",
                "orderByFields": "WD25CD",
                "f": "json",
                "resultOffset": str(offset),
                "resultRecordCount": str(page_size),
            }
        )
        data = fetch_json(query_url)
        features = data.get("features", [])
        if not features:
            raise RuntimeError(f"The official ONS ward lookup stopped early at offset {offset}.")

        for feature in features:
            attributes = feature["attributes"]
            code = attributes["WD25CD"]
            row = {
                "WD25CD": code,
                "WD25NM": attributes["WD25NM"].strip(),
                "LAD25CD": attributes["LAD25CD"],
                "LAD25NM": attributes["LAD25NM"].strip(),
            }
            existing = deduped.get(code)
            if existing is None:
                deduped[code] = row
                continue
            if existing != row:
                raise RuntimeError(f"Inconsistent duplicate ONS ward rows for {code}: {existing!r} != {row!r}")

        offset += len(features)

    rows = [deduped[code] for code in sorted(deduped)]
    if not rows:
        raise RuntimeError("The official ONS ward lookup returned no rows.")
    if len(rows) != expected_count:
        raise RuntimeError(f"Unexpected United Kingdom ward count: {len(rows)} != {expected_count}")
    return rows


def load_lad_qids(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing United Kingdom local authority district seed file: {path}")

    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    return {row["admin_code"]: row["territory_wikidata_id"] for row in rows}


def load_territory_snapshot(territory_sql: Path) -> dict[str, TerritorySnapshotRow]:
    if not territory_sql.is_file():
        raise FileNotFoundError(f"Missing territory snapshot SQL file: {territory_sql}")

    snapshot: dict[str, TerritorySnapshotRow] = {}
    for line_number, row in iter_rows(territory_sql):
        parsed = parse_sql_tuple(row, line_number)
        wikidata_id, name, type_code, country_iso, parent_wikidata_id = parsed[:5]
        if not wikidata_id or country_iso != "GB":
            continue

        payload = TerritorySnapshotRow(
            wikidata_id=wikidata_id,
            name=name,
            type_code=type_code,
            country_iso=country_iso,
            parent_wikidata_id=parent_wikidata_id,
        )
        existing = snapshot.get(wikidata_id)
        if existing is None:
            snapshot[wikidata_id] = payload
            continue
        if existing != payload:
            raise RuntimeError(
                f"Inconsistent duplicate territory snapshot row for {wikidata_id}: {existing!r} != {payload!r}"
            )
    return snapshot


def build_wikidata_query(ons_codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in ons_codes)
    return f"""
SELECT ?code ?item ?itemLabel ?itemDescription ?instanceOfLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P836 ?code .
  OPTIONAL {{ ?item wdt:P31 ?instanceOf . }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
}}
""".strip()


def build_wikidata_entity_query(qids: list[str]) -> str:
    values = " ".join(f"wd:{qid}" for qid in qids)
    return f"""
SELECT ?item ?itemLabel ?itemDescription ?instanceOfLabel WHERE {{
  VALUES ?item {{ {values} }}
  OPTIONAL {{ ?item wdt:P31 ?instanceOf . }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
}}
""".strip()


def load_wikidata_matches(
    ons_codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[WikidataMatch]]:
    matches_by_code: dict[str, dict[str, WikidataMatch]] = defaultdict(dict)
    for start in range(0, len(ons_codes), chunk_size):
        chunk = ons_codes[start : start + chunk_size]
        query = build_wikidata_query(chunk)
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query})
        for row in fetch_csv(query_url):
            qid = row["item"].rsplit("/", 1)[-1]
            payload = WikidataMatch(
                qid=qid,
                label=row["itemLabel"],
                description=row.get("itemDescription", ""),
                instance_of_label=row.get("instanceOfLabel", ""),
            )
            existing = matches_by_code[row["code"]].get(qid)
            if existing is None:
                matches_by_code[row["code"]][qid] = payload
                continue
            merged_instance_of = "; ".join(
                part
                for part in (existing.instance_of_label, payload.instance_of_label)
                if part and part not in existing.instance_of_label.split("; ")
            )
            matches_by_code[row["code"]][qid] = WikidataMatch(
                qid=qid,
                label=existing.label or payload.label,
                description=existing.description or payload.description,
                instance_of_label=merged_instance_of,
            )
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return {code: list(payloads.values()) for code, payloads in matches_by_code.items()}


def load_wikidata_entity_matches(
    qids: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, WikidataMatch]:
    matches_by_qid: dict[str, WikidataMatch] = {}
    for start in range(0, len(qids), chunk_size):
        chunk = qids[start : start + chunk_size]
        query = build_wikidata_entity_query(chunk)
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query})
        for row in fetch_csv(query_url):
            qid = row["item"].rsplit("/", 1)[-1]
            payload = WikidataMatch(
                qid=qid,
                label=row["itemLabel"],
                description=row.get("itemDescription", ""),
                instance_of_label=row.get("instanceOfLabel", ""),
            )
            existing = matches_by_qid.get(qid)
            if existing is None:
                matches_by_qid[qid] = payload
                continue
            merged_instance_of = "; ".join(
                part
                for part in (existing.instance_of_label, payload.instance_of_label)
                if part and part not in existing.instance_of_label.split("; ")
            )
            matches_by_qid[qid] = WikidataMatch(
                qid=qid,
                label=existing.label or payload.label,
                description=existing.description or payload.description,
                instance_of_label=merged_instance_of,
            )
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches_by_qid


def build_name_index(territory_snapshot: dict[str, TerritorySnapshotRow]) -> dict[str, list[str]]:
    index: dict[str, list[str]] = defaultdict(list)
    for row in territory_snapshot.values():
        for key in comparable_names(row.name):
            if row.wikidata_id not in index[key]:
                index[key].append(row.wikidata_id)
    return index


def has_ancestor(
    territory_snapshot: dict[str, TerritorySnapshotRow],
    start_qid: str,
    expected_ancestor_qid: str,
    *,
    max_depth: int = 10,
) -> bool:
    current_qid = start_qid
    depth = 0
    visited: set[str] = set()
    while current_qid and depth <= max_depth:
        if current_qid == expected_ancestor_qid:
            return True
        if current_qid in visited:
            return False
        visited.add(current_qid)
        row = territory_snapshot.get(current_qid)
        if row is None:
            return False
        current_qid = row.parent_wikidata_id
        depth += 1
    return False


def looks_like_uk_ward_entity(candidate: WikidataMatch) -> bool:
    descriptor = " ".join(
        part.strip().casefold()
        for part in (candidate.description, candidate.instance_of_label)
        if part and part.strip()
    )
    if not descriptor:
        return False
    return re.search(r"\b(electoral\s+ward|electoral\s+division|ward|division)s?\b", descriptor) is not None


def has_precise_uk_ward_class(candidate: WikidataMatch) -> bool:
    descriptor = " ".join(
        part.strip().casefold()
        for part in (candidate.description, candidate.instance_of_label)
        if part and part.strip()
    )
    if not descriptor:
        return False
    return (
        "ward or electoral division of the united kingdom" in descriptor
        or "electoral ward in " in descriptor
        or descriptor.startswith("electoral ward")
    )


def looks_like_latest_uk_ward_candidate(candidate: WikidataMatch) -> bool:
    descriptor = " ".join(
        part.strip().casefold()
        for part in (candidate.description, candidate.instance_of_label)
        if part and part.strip()
    )
    if not descriptor or "former" in descriptor:
        return False
    return (
        re.search(r"\(\d{4}\s*[–-]", descriptor) is not None
        or descriptor.startswith("ward or electoral division in ")
        or descriptor.startswith("electoral ward in ")
    )


def looks_like_current_admin_area(candidate: WikidataMatch) -> bool:
    descriptor = " ".join(
        part.strip().casefold()
        for part in (candidate.description, candidate.instance_of_label)
        if part and part.strip()
    )
    if not descriptor:
        return False
    if "former" in descriptor:
        return False
    if re.search(r"\b(village|civil parish|town|hamlet|suburb|railway station|station|building|church|school|library|manor|reservoir|lake|river|farm)\b", descriptor):
        return False
    return re.search(r"\b(ward|electoral|district|area)\b", descriptor) is not None


def enrich_candidates(
    candidates: list[WikidataMatch],
    entity_cache: dict[str, WikidataMatch],
) -> list[WikidataMatch]:
    missing_qids = [
        candidate.qid
        for candidate in candidates
        if not candidate.description and not candidate.instance_of_label and candidate.qid not in entity_cache
    ]
    if missing_qids:
        entity_cache.update(
            load_wikidata_entity_matches(
                sorted(set(missing_qids)),
                chunk_size=80,
                sleep_seconds=0.25,
            )
        )

    enriched: list[WikidataMatch] = []
    for candidate in candidates:
        if candidate.description or candidate.instance_of_label:
            enriched.append(candidate)
            continue
        cached = entity_cache.get(candidate.qid)
        if cached is None:
            enriched.append(candidate)
            continue
        enriched.append(
            WikidataMatch(
                qid=candidate.qid,
                label=cached.label or candidate.label,
                description=cached.description,
                instance_of_label=cached.instance_of_label or candidate.instance_of_label,
            )
        )
    return enriched


def resolve_qid(
    row: dict[str, str],
    candidates: list[WikidataMatch],
    territory_snapshot: dict[str, TerritorySnapshotRow],
    territory_name_index: dict[str, list[str]],
    parent_lad_qid: str,
    entity_cache: dict[str, WikidataMatch],
) -> str:
    code = row["WD25CD"]
    manual_qid = MANUAL_QID_OVERRIDES.get(code)
    if manual_qid is not None:
        if manual_qid not in territory_snapshot:
            raise RuntimeError(f"Manual UK ward override {code} -> {manual_qid} is missing from territory")
        if not has_ancestor(territory_snapshot, manual_qid, parent_lad_qid):
            raise RuntimeError(f"Manual UK ward override {code} -> {manual_qid} does not belong to {parent_lad_qid}")
        return manual_qid

    official_names = comparable_names(row["WD25NM"])
    current = list(candidates)
    if not current:
        current = [
            WikidataMatch(
                qid=qid,
                label=territory_snapshot[qid].name,
                description="",
                instance_of_label="",
            )
            for official_name in official_names
            for qid in territory_name_index.get(official_name, [])
        ]
        if not current:
            return ""

    current = [candidate for candidate in current if candidate.qid in territory_snapshot]
    if not current:
        return ""

    current = [
        candidate
        for candidate in current
        if candidate.qid == parent_lad_qid or has_ancestor(territory_snapshot, candidate.qid, parent_lad_qid)
    ]
    if not current:
        return ""

    if len(current) > 1 and any(not candidate.description and not candidate.instance_of_label for candidate in current):
        current = enrich_candidates(current, entity_cache)

    filters = [
        looks_like_latest_uk_ward_candidate,
        has_precise_uk_ward_class,
        looks_like_uk_ward_entity,
        looks_like_current_admin_area,
        lambda candidate: bool(comparable_names(territory_snapshot[candidate.qid].name) & official_names),
        lambda candidate: bool(comparable_names(candidate.label) & official_names),
        lambda candidate: territory_snapshot[candidate.qid].type_code == "region",
    ]

    for predicate in filters:
        filtered = [candidate for candidate in current if predicate(candidate)]
        if len(filtered) == 1:
            if territory_snapshot[filtered[0].qid].type_code != "region":
                current = filtered
                continue
            return filtered[0].qid
        if filtered:
            current = filtered

    if len(current) == 1 and current[0].qid in territory_snapshot:
        if territory_snapshot[current[0].qid].type_code != "region":
            return ""
        return current[0].qid

    if not any(looks_like_uk_ward_entity(candidate) or looks_like_current_admin_area(candidate) for candidate in current):
        return ""

    if all(looks_like_uk_ward_entity(candidate) for candidate in current):
        return max(current, key=lambda candidate: int(candidate.qid[1:])).qid

    raise RuntimeError(
        f"Expected exactly one Wikidata ward/division match for UK code {code} ({row['WD25NM']}), "
        f"got {current!r}"
    )


def build_seed_rows(
    ward_rows: list[dict[str, str]],
    lad_qids: dict[str, str],
    wikidata_matches: dict[str, list[WikidataMatch]],
    territory_snapshot: dict[str, TerritorySnapshotRow],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []
    seen_qids: set[str] = set()
    territory_name_index = build_name_index(territory_snapshot)
    entity_cache: dict[str, WikidataMatch] = {}
    errors: list[str] = []

    for row in ward_rows:
        parent_lad_code = row["LAD25CD"]
        parent_lad_qid = lad_qids.get(parent_lad_code)
        if parent_lad_qid is None:
            raise RuntimeError(f"Missing parent UK local authority district {parent_lad_code} for ward {row['WD25CD']}")

        try:
            qid = resolve_qid(
                row,
                wikidata_matches.get(row["WD25CD"], []),
                territory_snapshot,
                territory_name_index,
                parent_lad_qid,
                entity_cache,
            )
        except RuntimeError as exc:
            errors.append(str(exc))
            continue
        if qid and qid in seen_qids:
            raise RuntimeError(f"Duplicate UK ward/division mapping {qid} for code {row['WD25CD']}")
        if qid:
            seen_qids.add(qid)

        seed_rows.append(
            {
                "admin_code": row["WD25CD"],
                "display_name": row["WD25NM"],
                "territory_wikidata_id": qid,
                "parent_lad_code": parent_lad_code,
                "source": "seed.gb_electoral_ward_division",
            }
        )

    if errors:
        preview = "\n".join(errors[:20])
        remaining = len(errors) - 20
        if remaining > 0:
            preview += f"\n... and {remaining} more"
        raise RuntimeError(f"Could not resolve {len(errors)} UK ward/division rows:\n{preview}")

    return seed_rows


def write_seed(rows: list[dict[str, str]], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "admin_code",
                "display_name",
                "territory_wikidata_id",
                "parent_lad_code",
                "source",
            ],
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    ward_rows = load_ward_rows(args.ward_lookup_url, page_size=args.page_size)
    lad_qids = load_lad_qids(args.lad_seed)
    territory_snapshot = load_territory_snapshot(args.territory_sql)
    wikidata_matches = load_wikidata_matches(
        [row["WD25CD"] for row in ward_rows],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(ward_rows, lad_qids, wikidata_matches, territory_snapshot)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} UK electoral wards/divisions to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

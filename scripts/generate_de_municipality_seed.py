#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import re
import sys
import urllib.parse
import urllib.request
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from stream_territory_wikidata_sql import iter_rows, parse_sql_tuple


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "de_municipality_seed.tsv"
DEFAULT_BKG_URL = (
    "https://sgx.geodatenzentrum.de/wfs_vg5000_0101"
    "?service=WFS"
    "&version=2.0.0"
    "&request=GetFeature"
    "&TYPENAMES=vg5000_0101:vg5000_gem"
    "&outputFormat=csv"
    "&propertyName=ags,ars,gen,bez,ibz,sn_l,sn_r,sn_k,sn_v1,sn_v2,sn_g"
)
DEFAULT_KREIS_SEED_PATH = SCRIPT_DIR / "data" / "de_kreise_seed.tsv"
TERRITORY_SQL = ROOT / "liquibase/changelog" / "18-load-territory-from-wikidata.sql"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-de-municipality-seed/1.0 (local maintenance script)"
EXPECTED_COUNT = 10949
MANUAL_QID_OVERRIDES: dict[str, str] = {}
NORMALIZE_PATTERN = re.compile(r"[^0-9a-z]+")


@dataclass(frozen=True)
class TerritorySnapshotRow:
    wikidata_id: str
    name: str
    type_code: str
    country_iso: str
    parent_wikidata_id: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Germany municipality seed used by "
            "sync_admin_territory.sh from the official BKG VG5000 Gemeinde layer, "
            "Wikidata P439 mappings and the versioned territory snapshot."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--bkg-csv",
        default=DEFAULT_BKG_URL,
        help="Official BKG municipality CSV URL or local path.",
    )
    parser.add_argument(
        "--kreis-seed",
        type=Path,
        default=DEFAULT_KREIS_SEED_PATH,
        help=f"Path to de_kreise_seed.tsv (default: {DEFAULT_KREIS_SEED_PATH})",
    )
    parser.add_argument(
        "--territory-sql",
        type=Path,
        default=TERRITORY_SQL,
        help=f"Path to 18-load-territory-from-wikidata.sql (default: {TERRITORY_SQL})",
    )
    return parser.parse_args()


def fetch_text(source: str, *, accept: str) -> str:
    path = Path(source)
    if path.is_file():
        return path.read_text(encoding="utf-8-sig")

    request = urllib.request.Request(
        source,
        headers={
            "Accept": accept,
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8-sig")


def dedupe_bkg_rows(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    deduped: dict[str, dict[str, str]] = {}
    for row in rows:
        ags = row.get("ags", "").strip()
        if not ags:
            continue

        comparable = {
            "ags": ags,
            "ars": row["ars"].strip(),
            "gen": row["gen"].strip(),
            "bez": row["bez"].strip(),
            "ibz": row["ibz"].strip(),
            "sn_l": row["sn_l"].strip(),
            "sn_r": row["sn_r"].strip(),
            "sn_k": row["sn_k"].strip(),
            "sn_v1": row["sn_v1"].strip(),
            "sn_v2": row["sn_v2"].strip(),
            "sn_g": row["sn_g"].strip(),
        }
        existing = deduped.get(ags)
        if existing is None:
            deduped[ags] = comparable
            continue
        if existing != comparable:
            raise RuntimeError(f"Inconsistent duplicate BKG rows for AGS {ags}: {existing!r} != {comparable!r}")
    return deduped


def load_bkg_rows(source: str) -> dict[str, dict[str, str]]:
    rows = list(csv.DictReader(io.StringIO(fetch_text(source, accept="text/csv"))))
    deduped = dedupe_bkg_rows(rows)
    if len(deduped) != EXPECTED_COUNT:
        raise RuntimeError(f"Unexpected Germany municipality count: {len(deduped)} != {EXPECTED_COUNT}")
    return deduped


def load_kreis_codes(path: Path) -> set[str]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing Germany Kreis seed file: {path}")

    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    return {row["admin_code"] for row in rows}


def load_kreis_qids(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise FileNotFoundError(f"Missing Germany Kreis seed file: {path}")

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
        if not wikidata_id or country_iso != "DE":
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


def build_wikidata_query() -> str:
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  ?item wdt:P439 ?code ;
        wdt:P17 wd:Q183 .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "de,en". }}
}}
""".strip()


def load_wikidata_matches(
    ags_codes: set[str],
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": build_wikidata_query()})
    csv_text = fetch_text(query_url, accept="text/csv")
    for row in csv.DictReader(io.StringIO(csv_text)):
        code = row["code"]
        if code not in ags_codes or code in MANUAL_QID_OVERRIDES:
            continue
        payload = (row["item"].rsplit("/", 1)[-1], row["itemLabel"])
        if payload not in matches[code]:
            matches[code].append(payload)
    return matches


def normalize_name(value: str) -> str:
    return NORMALIZE_PATTERN.sub("", value.casefold())


def build_name_index(territory_snapshot: dict[str, TerritorySnapshotRow]) -> dict[str, list[str]]:
    index: dict[str, list[str]] = defaultdict(list)
    for row in territory_snapshot.values():
        index[normalize_name(row.name)].append(row.wikidata_id)
    return index


def has_ancestor(
    territory_snapshot: dict[str, TerritorySnapshotRow],
    start_qid: str,
    expected_ancestor_qid: str,
    *,
    max_depth: int = 12,
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


def resolve_qid(
    row: dict[str, str],
    candidates: list[tuple[str, str]],
    territory_snapshot: dict[str, TerritorySnapshotRow],
    territory_name_index: dict[str, list[str]],
    parent_kreis_qid: str,
) -> str:
    ags = row["ags"]
    manual_qid = MANUAL_QID_OVERRIDES.get(ags)
    if manual_qid is not None:
        if manual_qid not in territory_snapshot:
            raise RuntimeError(f"Manual Germany municipality override {ags} -> {manual_qid} is missing from territory")
        return manual_qid

    normalized_display_name = normalize_name(row["gen"])
    current = list(candidates)
    if not current:
        current = [
            (qid, territory_snapshot[qid].name)
            for qid in territory_name_index.get(normalized_display_name, [])
        ]
        if not current:
            raise RuntimeError(f"Missing Wikidata municipality match for German AGS {ags} ({row['gen']})")

    filters = [
        lambda candidate: candidate[0] in territory_snapshot,
        lambda candidate: candidate[0] == parent_kreis_qid
        or has_ancestor(territory_snapshot, candidate[0], parent_kreis_qid),
        lambda candidate: territory_snapshot[candidate[0]].type_code == "municipality",
        lambda candidate: normalize_name(territory_snapshot[candidate[0]].name) == normalized_display_name,
        lambda candidate: normalize_name(candidate[1]) == normalized_display_name,
    ]

    for predicate in filters:
        filtered = [candidate for candidate in current if predicate(candidate)]
        if len(filtered) == 1:
            return filtered[0][0]
        if filtered:
            current = filtered

    if len(current) == 1 and current[0][0] in territory_snapshot:
        return current[0][0]

    raise RuntimeError(
        f"Expected exactly one Wikidata municipality match for German AGS {ags} ({row['gen']}), "
        f"got {current!r}"
    )


def build_seed_rows(
    bkg_rows: dict[str, dict[str, str]],
    kreis_codes: set[str],
    kreis_qids: dict[str, str],
    wikidata_matches: dict[str, list[tuple[str, str]]],
    territory_snapshot: dict[str, TerritorySnapshotRow],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []
    seen_qids: set[str] = set()
    territory_name_index = build_name_index(territory_snapshot)

    for ags in sorted(bkg_rows):
        row = bkg_rows[ags]
        parent_kreis_code = ags[:5]
        if parent_kreis_code not in kreis_codes:
            raise RuntimeError(f"Missing parent German Kreis {parent_kreis_code} for municipality AGS {ags}")
        parent_kreis_qid = kreis_qids[parent_kreis_code]

        qid = resolve_qid(
            row,
            wikidata_matches.get(ags, []),
            territory_snapshot,
            territory_name_index,
            parent_kreis_qid,
        )
        if qid in seen_qids:
            raise RuntimeError(f"Duplicate Wikidata municipality mapping {qid} for AGS {ags}")
        seen_qids.add(qid)

        seed_rows.append(
            {
                "admin_code": ags,
                "display_name": row["gen"],
                "territory_wikidata_id": qid,
                "parent_kreis_code": parent_kreis_code,
                "source": "seed.de_admin_municipality",
            }
        )

    if len(seed_rows) != EXPECTED_COUNT:
        raise RuntimeError(f"Unexpected Germany municipality seed count: {len(seed_rows)} != {EXPECTED_COUNT}")
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
                "parent_kreis_code",
                "source",
            ],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    bkg_rows = load_bkg_rows(args.bkg_csv)
    kreis_codes = load_kreis_codes(args.kreis_seed)
    kreis_qids = load_kreis_qids(args.kreis_seed)
    territory_snapshot = load_territory_snapshot(args.territory_sql)
    wikidata_matches = load_wikidata_matches(set(bkg_rows))
    seed_rows = build_seed_rows(bkg_rows, kreis_codes, kreis_qids, wikidata_matches, territory_snapshot)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Germany municipalities to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

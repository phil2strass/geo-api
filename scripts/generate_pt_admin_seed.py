#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

from stream_territory_wikidata_sql import iter_rows, parse_sql_tuple


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "pt_admin_seed.tsv"
CAOP_CSV_URL = (
    "https://geo2.dgterritorio.gov.pt/geoserver/au/wfs"
    "?service=WFS&version=2.0.0&request=GetFeature"
    "&typeNames=au:AU.AdministrativeUnits"
    "&outputFormat=csv"
)
TERRITORY_SQL = ROOT / "liquibase/changelog/18-load-territory-from-wikidata.sql"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-pt-admin-seed/1.0 (local maintenance script)"
EXPECTED_COUNTS = {
    "district_or_island": 29,
    "municipality": 308,
    "civil_parish": 3092,
}
TOP_LEVEL_METADATA_BY_CODE = {
    "01": {"territory_wikidata_id": "Q210527", "territory_type": "region"},
    "02": {"territory_wikidata_id": "Q321455", "territory_type": "region"},
    "03": {"territory_wikidata_id": "Q326203", "territory_type": "region"},
    "04": {"territory_wikidata_id": "Q373528", "territory_type": "region"},
    "05": {"territory_wikidata_id": "Q273529", "territory_type": "region"},
    "06": {"territory_wikidata_id": "Q244517", "territory_type": "region"},
    "07": {"territory_wikidata_id": "Q274118", "territory_type": "region"},
    "08": {"territory_wikidata_id": "Q244521", "territory_type": "region"},
    "09": {"territory_wikidata_id": "Q273533", "territory_type": "region"},
    "10": {"territory_wikidata_id": "Q244512", "territory_type": "region"},
    "11": {"territory_wikidata_id": "Q207199", "territory_type": "region"},
    "12": {"territory_wikidata_id": "Q225189", "territory_type": "region"},
    "13": {"territory_wikidata_id": "Q322792", "territory_type": "region"},
    "14": {"territory_wikidata_id": "Q244510", "territory_type": "region"},
    "15": {"territory_wikidata_id": "Q274109", "territory_type": "region"},
    "16": {"territory_wikidata_id": "Q326214", "territory_type": "region"},
    "17": {"territory_wikidata_id": "Q379372", "territory_type": "region"},
    "18": {"territory_wikidata_id": "Q273525", "territory_type": "region"},
    "31": {"territory_wikidata_id": "Q30188", "territory_type": "region"},
    "32": {"territory_wikidata_id": "Q27320", "territory_type": "municipality"},
    "41": {"territory_wikidata_id": "Q217262", "territory_type": "region"},
    "42": {"territory_wikidata_id": "Q209036", "territory_type": "region"},
    "43": {"territory_wikidata_id": "Q215074", "territory_type": "region"},
    "44": {"territory_wikidata_id": "Q592315", "territory_type": "region"},
    "45": {"territory_wikidata_id": "Q743362", "territory_type": "region"},
    "46": {"territory_wikidata_id": "Q210811", "territory_type": "region"},
    "47": {"territory_wikidata_id": "Q657187", "territory_type": "region"},
    "48": {"territory_wikidata_id": "Q216752", "territory_type": "region"},
    "49": {"territory_wikidata_id": "Q954488", "territory_type": "region"},
}
MUNICIPALITY_QID_OVERRIDES: dict[str, str] = {}
CIVIL_PARISH_QID_OVERRIDES: dict[str, str] = {}


@dataclass(frozen=True)
class WikidataMatch:
    qid: str
    label: str
    statement_ended: str | None
    item_ended: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Portugal administrative seed used by sync_admin_territory.sh "
            "from the official DGT CAOP administrative-units CSV, Wikidata P6324 codes and "
            "the versioned territory snapshot."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--caop-csv",
        default=CAOP_CSV_URL,
        help="Official DGT CAOP administrative-units CSV URL or local path.",
    )
    parser.add_argument(
        "--territory-sql",
        type=Path,
        default=TERRITORY_SQL,
        help=f"Path to 18-load-territory-from-wikidata.sql (default: {TERRITORY_SQL})",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=150,
        help="Number of official Portugal codes per Wikidata request (default: 150).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=0.1,
        help="Delay between Wikidata requests (default: 0.1).",
    )
    return parser.parse_args()


def fetch_text(source: str) -> str:
    path = Path(source)
    if path.is_file():
        return path.read_text(encoding="utf-8-sig")

    request = urllib.request.Request(
        source,
        headers={
            "Accept": "text/csv",
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8-sig")


def load_caop_rows(source: str) -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    rows = [
        row
        for row in csv.DictReader(io.StringIO(fetch_text(source)))
        if row["tipo_area_"] == "Área Principal"
    ]
    if len(rows) != EXPECTED_COUNTS["civil_parish"]:
        raise RuntimeError(
            f"Unexpected Portugal civil parish count: {len(rows)} != {EXPECTED_COUNTS['civil_parish']}"
        )

    top_levels_by_code: dict[str, dict[str, str]] = {}
    municipalities_by_code: dict[str, dict[str, str]] = {}
    civil_parishes: list[dict[str, str]] = []

    for row in rows:
        parish_code = row["dtmnfr"].strip()
        top_level_code = parish_code[:2]
        municipality_code = parish_code[:4]
        parish_name = row["freguesia"].strip()
        municipality_name = row["municipio"].strip()
        top_level_name = row["distrito_i"].strip()

        if top_level_code not in TOP_LEVEL_METADATA_BY_CODE:
            raise RuntimeError(f"Unexpected Portugal parent code {top_level_code} in row {row!r}")
        if not parish_name or not municipality_name or not top_level_name:
            raise RuntimeError(f"Missing mandatory Portugal CAOP fields in row {row!r}")

        top_level_payload = {
            "admin_code": top_level_code,
            "display_name": top_level_name,
        }
        existing_top_level = top_levels_by_code.get(top_level_code)
        if existing_top_level is not None and existing_top_level != top_level_payload:
            raise RuntimeError(
                f"Conflicting Portugal top-level metadata for code {top_level_code}: "
                f"{existing_top_level!r} != {top_level_payload!r}"
            )
        top_levels_by_code[top_level_code] = top_level_payload

        municipality_payload = {
            "admin_code": municipality_code,
            "display_name": municipality_name,
            "parent_admin_code": top_level_code,
        }
        existing_municipality = municipalities_by_code.get(municipality_code)
        if existing_municipality is not None and existing_municipality != municipality_payload:
            raise RuntimeError(
                f"Conflicting Portugal municipality metadata for code {municipality_code}: "
                f"{existing_municipality!r} != {municipality_payload!r}"
            )
        municipalities_by_code[municipality_code] = municipality_payload

        civil_parishes.append(
            {
                "admin_code": parish_code,
                "display_name": parish_name,
                "parent_admin_code": municipality_code,
            }
        )

    if len(top_levels_by_code) != EXPECTED_COUNTS["district_or_island"]:
        raise RuntimeError(
            f"Unexpected Portugal district-or-island count: {len(top_levels_by_code)} != "
            f"{EXPECTED_COUNTS['district_or_island']}"
        )
    if len(municipalities_by_code) != EXPECTED_COUNTS["municipality"]:
        raise RuntimeError(
            f"Unexpected Portugal municipality count: {len(municipalities_by_code)} != "
            f"{EXPECTED_COUNTS['municipality']}"
        )

    top_levels = [top_levels_by_code[code] for code in sorted(top_levels_by_code)]
    municipalities = [municipalities_by_code[code] for code in sorted(municipalities_by_code)]
    civil_parishes.sort(key=lambda row: row["admin_code"])
    return top_levels, municipalities, civil_parishes


def load_snapshot_metadata(
    territory_sql: Path,
) -> tuple[set[str], dict[str, str], dict[str, list[str]], dict[str, str | None]]:
    if not territory_sql.is_file():
        raise FileNotFoundError(f"Missing territory snapshot SQL file: {territory_sql}")

    qids: set[str] = set()
    names_by_qid: dict[str, str] = {}
    qids_by_normalized_name: dict[str, list[str]] = defaultdict(list)
    parent_qid_by_qid: dict[str, str | None] = {}
    for line_number, row in iter_rows(territory_sql):
        if ", 'PT'," not in row:
            continue
        parsed = parse_sql_tuple(row, line_number)
        wikidata_id, name, _type_code, _country_iso, parent_qid = parsed[:5]
        if not wikidata_id:
            continue
        qids.add(wikidata_id)
        names_by_qid.setdefault(wikidata_id, name)
        parent_qid_by_qid.setdefault(wikidata_id, parent_qid or None)
        normalized_name = normalize_name(name)
        if wikidata_id not in qids_by_normalized_name[normalized_name]:
            qids_by_normalized_name[normalized_name].append(wikidata_id)
    return qids, names_by_qid, qids_by_normalized_name, parent_qid_by_qid


def build_wikidata_query(codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in codes)
    return f"""
SELECT ?code ?item ?itemLabel ?statementEnded ?itemEnded WHERE {{
  VALUES ?code {{ {values} }}
  ?item p:P6324 ?codeStatement .
  ?codeStatement ps:P6324 ?code .
  OPTIONAL {{ ?codeStatement pq:P582 ?statementEnded }}
  OPTIONAL {{ ?item wdt:P576 ?itemEnded }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "pt,en". }}
}}
""".strip()


def fetch_csv(query: str) -> list[dict[str, str]]:
    request = urllib.request.Request(
        WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query}),
        headers={
            "Accept": "text/csv",
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return list(csv.DictReader(io.StringIO(response.read().decode("utf-8"))))


def load_wikidata_matches(
    codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[WikidataMatch]]:
    matches: dict[str, dict[str, WikidataMatch]] = defaultdict(dict)
    for start in range(0, len(codes), chunk_size):
        chunk = codes[start : start + chunk_size]
        for row in fetch_csv(build_wikidata_query(chunk)):
            qid = row["item"].rsplit("/", 1)[-1]
            matches[row["code"]][qid] = WikidataMatch(
                qid=qid,
                label=row.get("itemLabel", ""),
                statement_ended=row.get("statementEnded") or None,
                item_ended=row.get("itemEnded") or None,
            )
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return {code: list(matches_by_qid.values()) for code, matches_by_qid in matches.items()}


def normalize_name(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    stripped = "".join(char for char in normalized if not unicodedata.combining(char))
    simplified = []
    for char in stripped.lower():
        if char.isalnum():
            simplified.append(char)
        else:
            simplified.append(" ")
    return " ".join("".join(simplified).split())


def resolve_unique(
    code: str,
    *,
    expected_name: str,
    matches: dict[str, list[WikidataMatch]],
    snapshot_qids: set[str],
    snapshot_names_by_qid: dict[str, str],
    snapshot_qids_by_normalized_name: dict[str, list[str]],
    snapshot_parent_qid_by_qid: dict[str, str | None],
    expected_parent_qid: str | None = None,
    manual_qid: str | None = None,
) -> tuple[str, str]:
    if manual_qid is not None:
        return manual_qid, snapshot_names_by_qid.get(manual_qid, expected_name)

    current_candidates = [
        candidate
        for candidate in matches.get(code, [])
        if candidate.statement_ended is None and candidate.item_ended is None
    ]
    if not current_candidates:
        name_candidates = snapshot_qids_by_normalized_name.get(normalize_name(expected_name), [])
        if expected_parent_qid is not None:
            name_candidates = [
                qid for qid in name_candidates if snapshot_parent_qid_by_qid.get(qid) == expected_parent_qid
            ]
        if len(name_candidates) == 1:
            qid = name_candidates[0]
            return qid, snapshot_names_by_qid.get(qid, expected_name)
        raise RuntimeError(f"Missing current Wikidata match for Portugal INE code {code}")

    if expected_parent_qid is not None:
        parent_candidates = [
            candidate
            for candidate in current_candidates
            if snapshot_parent_qid_by_qid.get(candidate.qid) == expected_parent_qid
        ]
        if len(parent_candidates) == 1:
            candidate = parent_candidates[0]
            return candidate.qid, snapshot_names_by_qid.get(candidate.qid, expected_name)
        if parent_candidates:
            current_candidates = parent_candidates

    if len(current_candidates) == 1:
        candidate = current_candidates[0]
        return candidate.qid, snapshot_names_by_qid.get(candidate.qid, expected_name)

    snapshot_candidates = [candidate for candidate in current_candidates if candidate.qid in snapshot_qids]
    if len(snapshot_candidates) == 1:
        candidate = snapshot_candidates[0]
        return candidate.qid, snapshot_names_by_qid.get(candidate.qid, expected_name)
    if snapshot_candidates:
        current_candidates = snapshot_candidates

    expected_key = normalize_name(expected_name)
    name_matches = [
        candidate
        for candidate in current_candidates
        if normalize_name(candidate.label) == expected_key
        or normalize_name(snapshot_names_by_qid.get(candidate.qid, "")) == expected_key
    ]
    if len(name_matches) == 1:
        candidate = name_matches[0]
        return candidate.qid, snapshot_names_by_qid.get(candidate.qid, expected_name)

    raise RuntimeError(
        f"Expected exactly one current Wikidata match for Portugal INE code {code} / {expected_name!r}, "
        f"got {current_candidates!r}"
    )


def build_seed_rows(
    top_levels: list[dict[str, str]],
    municipalities: list[dict[str, str]],
    civil_parishes: list[dict[str, str]],
    municipality_matches: dict[str, list[WikidataMatch]],
    civil_parish_matches: dict[str, list[WikidataMatch]],
    snapshot_qids: set[str],
    snapshot_names_by_qid: dict[str, str],
    snapshot_qids_by_normalized_name: dict[str, list[str]],
    snapshot_parent_qid_by_qid: dict[str, str | None],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []
    top_level_qid_by_code = {
        code: metadata["territory_wikidata_id"]
        for code, metadata in TOP_LEVEL_METADATA_BY_CODE.items()
    }
    municipality_qid_by_code: dict[str, str] = {}

    for top_level in top_levels:
        metadata = TOP_LEVEL_METADATA_BY_CODE[top_level["admin_code"]]
        seed_rows.append(
            {
                "level_code": "district_or_island",
                "admin_code": top_level["admin_code"],
                "display_name": top_level["display_name"],
                "territory_name": snapshot_names_by_qid.get(
                    metadata["territory_wikidata_id"],
                    top_level["display_name"],
                ),
                "territory_wikidata_id": metadata["territory_wikidata_id"],
                "territory_type": metadata["territory_type"],
                "parent_level_code": "",
                "parent_admin_code": "",
                "source": "seed.pt_admin_district_or_island",
            }
        )

    for municipality in municipalities:
        qid, territory_name = resolve_unique(
            municipality["admin_code"],
            expected_name=municipality["display_name"],
            matches=municipality_matches,
            snapshot_qids=snapshot_qids,
            snapshot_names_by_qid=snapshot_names_by_qid,
            snapshot_qids_by_normalized_name=snapshot_qids_by_normalized_name,
            snapshot_parent_qid_by_qid=snapshot_parent_qid_by_qid,
            expected_parent_qid=top_level_qid_by_code[municipality["parent_admin_code"]],
            manual_qid=MUNICIPALITY_QID_OVERRIDES.get(municipality["admin_code"]),
        )
        municipality_qid_by_code[municipality["admin_code"]] = qid
        seed_rows.append(
            {
                "level_code": "municipality",
                "admin_code": municipality["admin_code"],
                "display_name": municipality["display_name"],
                "territory_name": territory_name,
                "territory_wikidata_id": qid,
                "territory_type": "municipality",
                "parent_level_code": "district_or_island",
                "parent_admin_code": municipality["parent_admin_code"],
                "source": "seed.pt_admin_municipality",
            }
        )

    for civil_parish in civil_parishes:
        qid, territory_name = resolve_unique(
            civil_parish["admin_code"],
            expected_name=civil_parish["display_name"],
            matches=civil_parish_matches,
            snapshot_qids=snapshot_qids,
            snapshot_names_by_qid=snapshot_names_by_qid,
            snapshot_qids_by_normalized_name=snapshot_qids_by_normalized_name,
            snapshot_parent_qid_by_qid=snapshot_parent_qid_by_qid,
            expected_parent_qid=municipality_qid_by_code.get(civil_parish["parent_admin_code"]),
            manual_qid=CIVIL_PARISH_QID_OVERRIDES.get(civil_parish["admin_code"]),
        )
        seed_rows.append(
            {
                "level_code": "civil_parish",
                "admin_code": civil_parish["admin_code"],
                "display_name": civil_parish["display_name"],
                "territory_name": territory_name,
                "territory_wikidata_id": qid,
                "territory_type": "region",
                "parent_level_code": "municipality",
                "parent_admin_code": civil_parish["parent_admin_code"],
                "source": "seed.pt_admin_civil_parish",
            }
        )

    counts = Counter(row["level_code"] for row in seed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Portugal seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")
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
                "territory_name",
                "territory_wikidata_id",
                "territory_type",
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
    top_levels, municipalities, civil_parishes = load_caop_rows(args.caop_csv)
    (
        snapshot_qids,
        snapshot_names_by_qid,
        snapshot_qids_by_normalized_name,
        snapshot_parent_qid_by_qid,
    ) = load_snapshot_metadata(args.territory_sql)
    municipality_matches = load_wikidata_matches(
        [municipality["admin_code"] for municipality in municipalities],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    civil_parish_matches = load_wikidata_matches(
        [civil_parish["admin_code"] for civil_parish in civil_parishes],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(
        top_levels,
        municipalities,
        civil_parishes,
        municipality_matches,
        civil_parish_matches,
        snapshot_qids,
        snapshot_names_by_qid,
        snapshot_qids_by_normalized_name,
        snapshot_parent_qid_by_qid,
    )
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Portugal administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

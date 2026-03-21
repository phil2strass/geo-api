#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import sys
import time
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

from stream_territory_wikidata_sql import iter_rows, parse_sql_tuple


SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "fr_admin_seed.tsv"
DEFAULT_COMMUNES_CSV = "https://www.insee.fr/fr/statistiques/fichier/8740222/v_commune_2026.csv"
DEFAULT_CANTONS_CSV = "https://www.insee.fr/fr/statistiques/fichier/8740222/v_canton_2026.csv"
DEFAULT_ARRONDISSEMENTS_CSV = "https://www.insee.fr/fr/statistiques/fichier/8740222/v_arrondissement_2026.csv"
TERRITORY_SQL = ROOT / "liquibase/changelog" / "18-load-territory-from-wikidata.sql"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-fr-admin-seed/1.0 (local maintenance script)"
EXPECTED_COUNTS = {
    "arrondissement": 333,
    "canton": 2054,
    "commune": 34875,
}
WIKIDATA_PROPERTY_BY_LEVEL = {
    "arrondissement": "P3423",
    "canton": "P2506",
    "commune": "P374",
}
WIKIDATA_CLASS_BY_LEVEL = {
    "arrondissement": "Q194203",
    "canton": "Q18524218",
    "commune": "Q484170",
}
MANUAL_QID_OVERRIDES: dict[str, dict[str, str]] = {
    "arrondissement": {
        # Current arrondissement item still carries an outdated end date in Wikidata.
        "913": "Q539378",
    },
    "canton": {},
    "commune": {
        # Current commune and a duplicate "Montlieu" item both expose the same code.
        "17243": "Q1084654",
        # Current commune item exists in territory but is not typed as commune française in Wikidata.
        "75056": "Q90",
        # Territory snapshot currently carries the right item under the wrong country and is fixed by migration 38.
        "67554": "Q21533",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated France administrative seed used by sync_admin_territory.sh "
            "from the official Insee COG 2026 files, Wikidata code properties and the "
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
        "--communes-csv",
        default=DEFAULT_COMMUNES_CSV,
        help="Official Insee communes CSV URL or local path.",
    )
    parser.add_argument(
        "--cantons-csv",
        default=DEFAULT_CANTONS_CSV,
        help="Official Insee cantons CSV URL or local path.",
    )
    parser.add_argument(
        "--arrondissements-csv",
        default=DEFAULT_ARRONDISSEMENTS_CSV,
        help="Official Insee arrondissements CSV URL or local path.",
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
        help="Number of official codes per Wikidata request (default: 150).",
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


def load_csv_rows(source: str) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(fetch_text(source))))


def load_arrondissement_seed_rows(source: str) -> list[dict[str, str]]:
    rows = sorted(load_csv_rows(source), key=lambda row: row["ARR"])
    if len(rows) != EXPECTED_COUNTS["arrondissement"]:
        raise RuntimeError(
            f"Unexpected France arrondissement count: {len(rows)} != "
            f"{EXPECTED_COUNTS['arrondissement']}"
        )

    return [
        {
            "level_code": "arrondissement",
            "admin_code": row["ARR"],
            "display_name": row["LIBELLE"],
            "wikidata_code": row["ARR"],
            "parent_level_code": "department",
            "parent_admin_code": row["DEP"],
            "source": "seed.fr_admin_arrondissement",
        }
        for row in rows
    ]


def load_canton_seed_rows(source: str) -> list[dict[str, str]]:
    rows = sorted(
        (row for row in load_csv_rows(source) if row["TYPECT"] == "C"),
        key=lambda row: row["CAN"],
    )
    if len(rows) != EXPECTED_COUNTS["canton"]:
        raise RuntimeError(
            f"Unexpected France canton count: {len(rows)} != {EXPECTED_COUNTS['canton']}"
        )

    return [
        {
            "level_code": "canton",
            "admin_code": row["CAN"],
            "display_name": row["LIBELLE"],
            "wikidata_code": row["CAN"],
            "parent_level_code": "department",
            "parent_admin_code": row["DEP"],
            "source": "seed.fr_admin_canton",
        }
        for row in rows
    ]


def load_commune_seed_rows(source: str) -> list[dict[str, str]]:
    rows = sorted(
        (row for row in load_csv_rows(source) if row["TYPECOM"] == "COM"),
        key=lambda row: row["COM"],
    )
    if len(rows) != EXPECTED_COUNTS["commune"]:
        raise RuntimeError(
            f"Unexpected France commune count: {len(rows)} != {EXPECTED_COUNTS['commune']}"
        )

    return [
        {
            "level_code": "commune",
            "admin_code": row["COM"],
            "display_name": row["LIBELLE"],
            "wikidata_code": row["COM"],
            "parent_level_code": "department",
            "parent_admin_code": row["DEP"],
            "source": "seed.fr_admin_commune",
        }
        for row in rows
    ]


def load_territory_qids(territory_sql: Path) -> set[str]:
    if not territory_sql.is_file():
        raise FileNotFoundError(f"Missing territory snapshot SQL file: {territory_sql}")

    qids: set[str] = set()
    for line_number, row in iter_rows(territory_sql):
        parsed = parse_sql_tuple(row, line_number)
        wikidata_id, _name, _type_code, _country_iso = parsed[:4]
        if wikidata_id:
            qids.add(wikidata_id)
    return qids


def build_wikidata_query(level_code: str, codes: list[str]) -> str:
    property_id = WIKIDATA_PROPERTY_BY_LEVEL[level_code]
    class_qid = WIKIDATA_CLASS_BY_LEVEL[level_code]
    values = " ".join(f'"{code}"' for code in codes)

    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P31 wd:{class_qid} .
  ?item p:{property_id} ?code_statement .
  ?code_statement ps:{property_id} ?code .
  FILTER NOT EXISTS {{ ?code_statement pq:P582 [] }}
  FILTER NOT EXISTS {{ ?item wdt:P576 [] }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "fr,en". }}
}}
""".strip()


def fetch_wikidata_csv(query: str) -> list[dict[str, str]]:
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
    level_code: str,
    codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for start in range(0, len(codes), chunk_size):
        chunk = codes[start : start + chunk_size]
        for row in fetch_wikidata_csv(build_wikidata_query(level_code, chunk)):
            qid = row["item"].rsplit("/", 1)[-1]
            payload = (qid, row["itemLabel"])
            if payload not in matches[row["code"]]:
                matches[row["code"]].append(payload)
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches


def resolve_qid(
    level_code: str,
    code: str,
    candidates: list[tuple[str, str]],
    territory_qids: set[str],
) -> str:
    manual_qid = MANUAL_QID_OVERRIDES[level_code].get(code)
    if manual_qid is not None:
        if manual_qid not in territory_qids:
            raise RuntimeError(
                f"Manual {level_code} override {code} -> {manual_qid} is missing from the territory snapshot."
            )
        return manual_qid

    if not candidates:
        raise RuntimeError(f"Missing Wikidata match for French {level_code} code {code}.")

    snapshot_candidates = [qid for qid, _label in candidates if qid in territory_qids]
    unique_snapshot_candidates = sorted(set(snapshot_candidates))
    if len(unique_snapshot_candidates) == 1:
        return unique_snapshot_candidates[0]
    if len(unique_snapshot_candidates) > 1:
        raise RuntimeError(
            f"Multiple territory snapshot matches for French {level_code} code {code}: "
            f"{unique_snapshot_candidates!r}"
        )

    if len(candidates) == 1:
        qid, label = candidates[0]
        raise RuntimeError(
            f"Wikidata match for French {level_code} code {code} resolves to {qid} ({label}), "
            "but this item is missing from the territory snapshot."
        )

    raise RuntimeError(
        f"Ambiguous Wikidata matches for French {level_code} code {code}: {candidates!r}"
    )


def build_seed_rows(
    seed_rows: list[dict[str, str]],
    territory_qids: set[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> list[dict[str, str]]:
    codes_by_level: dict[str, list[str]] = defaultdict(list)
    for row in seed_rows:
        codes_by_level[row["level_code"]].append(row["wikidata_code"])

    matches_by_level = {
        level_code: load_wikidata_matches(
            level_code,
            codes,
            chunk_size=chunk_size,
            sleep_seconds=sleep_seconds,
        )
        for level_code, codes in codes_by_level.items()
    }

    resolved_rows: list[dict[str, str]] = []
    for row in seed_rows:
        level_code = row["level_code"]
        wikidata_code = row["wikidata_code"]
        resolved_rows.append(
            {
                "level_code": level_code,
                "admin_code": row["admin_code"],
                "display_name": row["display_name"],
                "territory_wikidata_id": resolve_qid(
                    level_code,
                    wikidata_code,
                    matches_by_level[level_code].get(wikidata_code, []),
                    territory_qids,
                ),
                "parent_level_code": row["parent_level_code"],
                "parent_admin_code": row["parent_admin_code"],
                "source": row["source"],
            }
        )

    counts = Counter(row["level_code"] for row in resolved_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected France seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")

    return resolved_rows


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
    territory_qids = load_territory_qids(args.territory_sql)
    raw_seed_rows = (
        load_arrondissement_seed_rows(args.arrondissements_csv)
        + load_canton_seed_rows(args.cantons_csv)
        + load_commune_seed_rows(args.communes_csv)
    )
    resolved_rows = build_seed_rows(
        raw_seed_rows,
        territory_qids,
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    write_seed(resolved_rows, args.output)
    print(f"Wrote {len(resolved_rows)} France administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import json
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "gb_local_authority_district_seed.tsv"
ONS_LAD_LOOKUP_URL = (
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/"
    "LAD25_CTRY25_UK_LU/FeatureServer/0/query"
)
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-gb-lad-seed/1.0 (local maintenance script)"
MANUAL_QID_OVERRIDES = {
    # Wikidata is missing P836 on the current metropolitan borough item.
    "E08000038": "Q1857382",  # Barnsley
    # Wikidata is missing P836 on the current metropolitan borough item.
    "E08000039": "Q12956644",  # Sheffield
    # ONS uses the current Gaelic authority name; Wikidata's territorial item keeps the
    # more common English label but still represents the council area.
    "S12000013": "Q80967",  # Na h-Eileanan Siar / Outer Hebrides
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated United Kingdom local authority district seed used by "
            "sync_admin_territory.sh from the official ONS 2025 LAD-to-country lookup "
            "and Wikidata GSS code mappings."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=80,
        help="Number of ONS codes per Wikidata SPARQL request (default: 80).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between Wikidata requests (default: 1.0).",
    )
    return parser.parse_args()


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": WIKIDATA_USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.loads(response.read().decode("utf-8"))


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


def normalize_label(value: str) -> str:
    return value.casefold().replace("’", "'").replace("‘", "'").strip()


def load_lad_rows() -> list[dict[str, str]]:
    query_url = ONS_LAD_LOOKUP_URL + "?" + urllib.parse.urlencode(
        {
            "where": "1=1",
            "outFields": "LAD25CD,LAD25NM,CTRY25CD,CTRY25NM",
            "returnGeometry": "false",
            "f": "json",
            "resultRecordCount": "2000",
        }
    )
    data = fetch_json(query_url)
    rows = [feature["attributes"] for feature in data["features"]]
    rows.sort(key=lambda row: row["LAD25CD"])
    return rows


def build_wikidata_query(ons_codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in ons_codes)
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P836 ?code .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
}}
""".strip()


def load_wikidata_matches(
    ons_codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for start in range(0, len(ons_codes), chunk_size):
        chunk = ons_codes[start : start + chunk_size]
        query = build_wikidata_query(chunk)
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query})
        for row in fetch_csv(query_url):
            qid = row["item"].rsplit("/", 1)[-1]
            matches[row["code"]].append((qid, row["itemLabel"]))
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches


def resolve_qid(code: str, official_name: str, candidates: list[tuple[str, str]]) -> str:
    manual_qid = MANUAL_QID_OVERRIDES.get(code)
    if manual_qid is not None:
        return manual_qid
    if len(candidates) == 1:
        return candidates[0][0]

    normalized_name = normalize_label(official_name)
    exact_non_council = [
        candidate
        for candidate in candidates
        if normalize_label(candidate[1]) == normalized_name
        and "council" not in normalize_label(candidate[1])
    ]
    if len(exact_non_council) == 1:
        return exact_non_council[0][0]

    exact = [candidate for candidate in candidates if normalize_label(candidate[1]) == normalized_name]
    if len(exact) == 1:
        return exact[0][0]

    non_council = [candidate for candidate in candidates if "council" not in normalize_label(candidate[1])]
    if len(non_council) == 1:
        return non_council[0][0]

    raise RuntimeError(f"Could not resolve Wikidata item for {code} {official_name}: {candidates!r}")


def build_seed_rows(
    lad_rows: list[dict[str, str]],
    wikidata_matches: dict[str, list[tuple[str, str]]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []
    for row in lad_rows:
        code = row["LAD25CD"]
        seed_rows.append(
            {
                "admin_code": code,
                "display_name": row["LAD25NM"],
                "territory_wikidata_id": resolve_qid(code, row["LAD25NM"], wikidata_matches.get(code, [])),
                "parent_country_code": row["CTRY25CD"],
                "source": "seed.gb_local_authority_district",
            }
        )
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
                "parent_country_code",
                "source",
            ],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    lad_rows = load_lad_rows()
    wikidata_matches = load_wikidata_matches(
        [row["LAD25CD"] for row in lad_rows],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(lad_rows, wikidata_matches)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} UK local authority districts to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

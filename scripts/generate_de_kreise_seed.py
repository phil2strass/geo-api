#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "de_kreise_seed.tsv"
DEFAULT_BKG_URL = (
    "https://sgx.geodatenzentrum.de/wfs_vg1000"
    "?service=WFS"
    "&version=2.0.0"
    "&request=GetFeature"
    "&TYPENAMES=vg1000_krs"
    "&outputFormat=csv"
    "&propertyName=ags,gen,bez,ibz,sn_l,sn_r,sn_k,debkg_id"
)
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-de-kreise-seed/1.0 (local maintenance script)"
ACTIVE_GOVERNMENT_REGION_STATES = {"05", "06", "08", "09"}
MANUAL_QID_OVERRIDES = {
    # Wikidata currently has a non-administrative item sharing AGS 03353.
    "03353": "Q5907",
    # Wikidata currently lacks P440 on the official kreisfreie Stadt item.
    "16056": "Q7070",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Germany Kreis seed used by sync_admin_territory.sh "
            "from the official BKG VG1000 WFS and Wikidata P440 mappings."
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
        type=Path,
        help="Optional local BKG CSV file. If omitted, the official WFS CSV is downloaded.",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=80,
        help="Number of AGS codes per Wikidata SPARQL request (default: 80).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between Wikidata requests to avoid hammering the endpoint (default: 1.0).",
    )
    return parser.parse_args()


def fetch_text(url: str, *, accept: str) -> str:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": accept,
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8")


def load_bkg_rows(input_csv: Path | None) -> dict[str, dict[str, str]]:
    if input_csv is None:
        csv_text = fetch_text(DEFAULT_BKG_URL, accept="text/csv")
        rows = csv.DictReader(io.StringIO(csv_text))
    else:
        with input_csv.open(newline="", encoding="utf-8") as handle:
            rows = csv.DictReader(handle)
            rows = list(rows)
        return dedupe_bkg_rows(rows)

    return dedupe_bkg_rows(list(rows))


def dedupe_bkg_rows(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    deduped: dict[str, dict[str, str]] = {}
    for row in rows:
        ags = row["ags"]
        comparable = {
            "ags": row["ags"],
            "gen": row["gen"],
            "bez": row["bez"],
            "ibz": row["ibz"],
            "sn_l": row["sn_l"],
            "sn_r": row["sn_r"],
            "sn_k": row["sn_k"],
        }
        existing = deduped.get(ags)
        if existing is None:
            deduped[ags] = comparable
            continue
        if existing != comparable:
            raise RuntimeError(f"Inconsistent duplicate BKG rows for AGS {ags}: {existing!r} != {comparable!r}")
    return deduped


def build_wikidata_query(ags_codes: list[str]) -> str:
    values = " ".join(f'"{ags}"' for ags in ags_codes)
    return f"""
SELECT ?item ?ags ?itemLabel WHERE {{
  VALUES ?ags {{ {values} }}
  ?item wdt:P440 ?ags ;
        wdt:P17 wd:Q183 .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "de,en". }}
}}
""".strip()


def load_wikidata_matches(
    ags_codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for start in range(0, len(ags_codes), chunk_size):
        chunk = [ags for ags in ags_codes[start : start + chunk_size] if ags not in MANUAL_QID_OVERRIDES]
        if not chunk:
            continue
        query = build_wikidata_query(chunk)
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query})
        csv_text = fetch_text(query_url, accept="text/csv")
        for row in csv.DictReader(io.StringIO(csv_text)):
            qid = row["item"].rsplit("/", 1)[-1]
            matches[row["ags"]].append((qid, row["itemLabel"]))
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches


def resolve_qid(ags: str, candidates: list[tuple[str, str]]) -> str:
    manual_qid = MANUAL_QID_OVERRIDES.get(ags)
    if manual_qid is not None:
        return manual_qid
    if len(candidates) != 1:
        raise RuntimeError(f"Expected exactly one Wikidata match for AGS {ags}, got {candidates!r}")
    return candidates[0][0]


def build_seed_rows(
    bkg_rows: dict[str, dict[str, str]],
    wikidata_matches: dict[str, list[tuple[str, str]]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []
    for ags in sorted(bkg_rows):
        row = bkg_rows[ags]
        parent_government_region_code = ags[:3] if row["sn_l"] in ACTIVE_GOVERNMENT_REGION_STATES else ""
        seed_rows.append(
            {
                "admin_code": ags,
                "display_name": row["gen"],
                "territory_wikidata_id": resolve_qid(ags, wikidata_matches.get(ags, [])),
                "parent_state_code": row["sn_l"],
                "parent_government_region_code": parent_government_region_code,
                "source": "seed.de_admin_kreis",
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
                "parent_state_code",
                "parent_government_region_code",
                "source",
            ],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    bkg_rows = load_bkg_rows(args.bkg_csv)
    wikidata_matches = load_wikidata_matches(
        sorted(bkg_rows),
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(bkg_rows, wikidata_matches)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Germany Kreise to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

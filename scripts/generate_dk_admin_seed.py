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


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "dk_admin_seed.tsv"
DST_REGIONS_MUNICIPALITIES_CSV_URL = (
    "https://www.dst.dk/Site/Dst/SingleFiles/GetArchiveFile.aspx"
    "?fi=187984160802&fo=0&ext=kvaldel"
)
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-dk-admin-seed/1.0 (local maintenance script)"
EXPECTED_COUNTS = {
    "region": 5,
    "municipality": 98,
    "state_managed_area": 1,
}
REGION_QIDS_BY_CODE = {
    "084": "Q26073",  # Region Hovedstaden
    "085": "Q26589",  # Region Sjaelland
    "083": "Q26061",  # Region Syddanmark
    "082": "Q26586",  # Region Midtjylland
    "081": "Q26067",  # Region Nordjylland
}
SPECIAL_AREA_QIDS_BY_CODE = {
    "411": "Q502678",  # Ertholmene / Christianso
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Denmark administrative seed used by sync_admin_territory.sh "
            "from the official DST regions/landsdele/municipalities CSV and Wikidata kommunekoder."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--dst-csv",
        default=DST_REGIONS_MUNICIPALITIES_CSV_URL,
        help="Official DST CSV URL or local path.",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=80,
        help="Number of Danish municipality codes per Wikidata SPARQL request (default: 80).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between Wikidata requests (default: 1.0).",
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


def load_dst_rows(source: str) -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    csv_text = fetch_text(source)
    rows = list(csv.DictReader(io.StringIO(csv_text), delimiter=";"))

    regions: list[dict[str, str]] = []
    municipalities: list[dict[str, str]] = []
    state_managed_areas: list[dict[str, str]] = []
    current_region_code = ""

    for row in rows:
        level = row["NIVEAU"]
        code = row["KODE"].zfill(3 if level in {"1", "3"} else 2)
        title = row["TITEL"].strip()

        if level == "1":
            current_region_code = code
            regions.append(
                {
                    "admin_code": code,
                    "display_name": title,
                    "source": "seed.dk_admin_region",
                }
            )
            continue

        if level != "3":
            continue

        if code in SPECIAL_AREA_QIDS_BY_CODE:
            state_managed_areas.append(
                {
                    "admin_code": code,
                    "display_name": title,
                    "parent_admin_code": current_region_code,
                    "source": "seed.dk_admin_state_managed_area",
                }
            )
            continue

        municipalities.append(
            {
                "admin_code": code,
                "display_name": title,
                "parent_admin_code": current_region_code,
                "source": "seed.dk_admin_municipality",
            }
        )

    counts = {
        "region": len(regions),
        "municipality": len(municipalities),
        "state_managed_area": len(state_managed_areas),
    }
    if counts != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Denmark DST counts: {counts!r} != {EXPECTED_COUNTS!r}")

    return regions, municipalities, state_managed_areas


def build_wikidata_query(codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in codes)
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P1168 ?code ;
        wdt:P31 wd:Q2177636 .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "da,en". }}
}}
""".strip()


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


def load_wikidata_matches(
    codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for start in range(0, len(codes), chunk_size):
        chunk = codes[start : start + chunk_size]
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": build_wikidata_query(chunk)})
        for row in fetch_csv(query_url):
            qid = row["item"].rsplit("/", 1)[-1]
            matches[row["code"]].append((qid, row["itemLabel"]))
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches


def resolve_unique(code: str, matches: dict[str, list[tuple[str, str]]]) -> tuple[str, str]:
    candidates = matches.get(code, [])
    if len(candidates) != 1:
        raise RuntimeError(
            f"Expected exactly one Wikidata match for Danish kommunekode {code}, got {candidates!r}"
        )
    return candidates[0]


def build_seed_rows(
    regions: list[dict[str, str]],
    municipalities: list[dict[str, str]],
    state_managed_areas: list[dict[str, str]],
    wikidata_matches: dict[str, list[tuple[str, str]]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []

    for region in regions:
        qid = REGION_QIDS_BY_CODE.get(region["admin_code"])
        if qid is None:
            raise RuntimeError(f"Missing region QID mapping for {region['admin_code']}")
        seed_rows.append(
            {
                "level_code": "region",
                "admin_code": region["admin_code"],
                "display_name": region["display_name"],
                "territory_wikidata_id": qid,
                "parent_level_code": "",
                "parent_admin_code": "",
                "source": region["source"],
            }
        )

    for municipality in municipalities:
        qid, _territory_name = resolve_unique(municipality["admin_code"], wikidata_matches)
        seed_rows.append(
            {
                "level_code": "municipality",
                "admin_code": municipality["admin_code"],
                "display_name": municipality["display_name"],
                "territory_wikidata_id": qid,
                "parent_level_code": "region",
                "parent_admin_code": municipality["parent_admin_code"],
                "source": municipality["source"],
            }
        )

    for area in state_managed_areas:
        qid = SPECIAL_AREA_QIDS_BY_CODE[area["admin_code"]]
        seed_rows.append(
            {
                "level_code": "state_managed_area",
                "admin_code": area["admin_code"],
                "display_name": area["display_name"],
                "territory_wikidata_id": qid,
                "parent_level_code": "region",
                "parent_admin_code": area["parent_admin_code"],
                "source": area["source"],
            }
        )

    counts = Counter(row["level_code"] for row in seed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Denmark seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")
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
    regions, municipalities, state_managed_areas = load_dst_rows(args.dst_csv)
    wikidata_matches = load_wikidata_matches(
        [row["admin_code"] for row in municipalities],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(regions, municipalities, state_managed_areas, wikidata_matches)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Denmark administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

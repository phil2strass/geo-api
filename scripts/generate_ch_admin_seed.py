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
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "ch_admin_seed.tsv"
BFS_LEVELS_CSV_URL = "https://www.agvchapp.bfs.admin.ch/api/communes/levels?date=01-01-2026&format=csv"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-ch-admin-seed/1.0 (local maintenance script)"
EXPECTED_COUNTS = {
    "canton": 26,
    "municipality": 2110,
}
CANTON_METADATA_BY_ID = {
    "1": {"admin_code": "ZH", "territory_wikidata_id": "Q11943"},
    "2": {"admin_code": "BE", "territory_wikidata_id": "Q11911"},
    "3": {"admin_code": "LU", "territory_wikidata_id": "Q12121"},
    "4": {"admin_code": "UR", "territory_wikidata_id": "Q12404"},
    "5": {"admin_code": "SZ", "territory_wikidata_id": "Q12433"},
    "6": {"admin_code": "OW", "territory_wikidata_id": "Q12573"},
    "7": {"admin_code": "NW", "territory_wikidata_id": "Q12592"},
    "8": {"admin_code": "GL", "territory_wikidata_id": "Q11922"},
    "9": {"admin_code": "ZG", "territory_wikidata_id": "Q11933"},
    "10": {"admin_code": "FR", "territory_wikidata_id": "Q12640"},
    "11": {"admin_code": "SO", "territory_wikidata_id": "Q11929"},
    "12": {"admin_code": "BS", "territory_wikidata_id": "Q12172"},
    "13": {"admin_code": "BL", "territory_wikidata_id": "Q12146"},
    "14": {"admin_code": "SH", "territory_wikidata_id": "Q12697"},
    "15": {"admin_code": "AR", "territory_wikidata_id": "Q12079"},
    "16": {"admin_code": "AI", "territory_wikidata_id": "Q12094"},
    "17": {"admin_code": "SG", "territory_wikidata_id": "Q12746"},
    "18": {"admin_code": "GR", "territory_wikidata_id": "Q11925"},
    "19": {"admin_code": "AG", "territory_wikidata_id": "Q11972"},
    "20": {"admin_code": "TG", "territory_wikidata_id": "Q12713"},
    "21": {"admin_code": "TI", "territory_wikidata_id": "Q12724"},
    "22": {"admin_code": "VD", "territory_wikidata_id": "Q12771"},
    "23": {"admin_code": "VS", "territory_wikidata_id": "Q834"},
    "24": {"admin_code": "NE", "territory_wikidata_id": "Q12738"},
    "25": {"admin_code": "GE", "territory_wikidata_id": "Q11917"},
    "26": {"admin_code": "JU", "territory_wikidata_id": "Q12755"},
}
MUNICIPALITY_QID_OVERRIDES = {
    # Current municipality item exists in territory but is still missing BFS code P771 in Wikidata.
    "2056": "Q133571724",  # Fetigny-Menieres
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Switzerland administrative seed used by sync_admin_territory.sh "
            "from the official BFS communes levels CSV and the Wikidata Swiss municipality code mapping."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--bfs-levels-csv",
        default=BFS_LEVELS_CSV_URL,
        help="Official BFS levels CSV URL or local path.",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=100,
        help="Number of Swiss municipality codes per Wikidata SPARQL request (default: 100).",
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


def load_bfs_rows(source: str) -> tuple[list[dict[str, str]], dict[str, str]]:
    csv_text = fetch_text(source)
    municipalities = list(csv.DictReader(io.StringIO(csv_text)))

    municipality_count = len(municipalities)
    if municipality_count != EXPECTED_COUNTS["municipality"]:
        raise RuntimeError(
            f"Unexpected Switzerland municipality count: {municipality_count} != "
            f"{EXPECTED_COUNTS['municipality']}"
        )

    canton_name_by_id: dict[str, str] = {}
    for row in municipalities:
        canton_id = row["CantonId"].strip()
        canton_name = row["Canton"].strip()
        bfs_code = row["BfsCode"].strip()
        municipality_name = row["Name"].strip()

        if not canton_id or not canton_name:
            raise RuntimeError(f"Missing canton fields in BFS row: {row!r}")
        if not bfs_code or not municipality_name:
            raise RuntimeError(f"Missing municipality fields in BFS row: {row!r}")

        existing = canton_name_by_id.get(canton_id)
        if existing is not None and existing != canton_name:
            raise RuntimeError(
                f"Conflicting canton labels for CantonId {canton_id}: {existing!r} != {canton_name!r}"
            )
        canton_name_by_id[canton_id] = canton_name

    if len(canton_name_by_id) != EXPECTED_COUNTS["canton"]:
        raise RuntimeError(
            f"Unexpected Switzerland canton count: {len(canton_name_by_id)} != "
            f"{EXPECTED_COUNTS['canton']}"
        )

    missing_metadata = sorted(set(canton_name_by_id) - set(CANTON_METADATA_BY_ID))
    if missing_metadata:
        raise RuntimeError(f"Missing canton metadata for BFS canton ids: {missing_metadata!r}")

    return municipalities, canton_name_by_id


def build_wikidata_query(codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in codes)
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P771 ?code ;
        wdt:P31 wd:Q70208 .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "de,fr,it,en". }}
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
            f"Expected exactly one Wikidata match for Swiss BFS municipality code {code}, "
            f"got {candidates!r}"
        )
    return candidates[0]


def build_seed_rows(
    municipalities: list[dict[str, str]],
    canton_name_by_id: dict[str, str],
    wikidata_matches: dict[str, list[tuple[str, str]]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []

    for canton_id in sorted(canton_name_by_id, key=int):
        metadata = CANTON_METADATA_BY_ID[canton_id]
        seed_rows.append(
            {
                "level_code": "canton",
                "admin_code": metadata["admin_code"],
                "display_name": canton_name_by_id[canton_id],
                "territory_wikidata_id": metadata["territory_wikidata_id"],
                "parent_level_code": "",
                "parent_admin_code": "",
                "source": "seed.ch_admin_canton",
            }
        )

    for municipality in sorted(municipalities, key=lambda row: int(row["BfsCode"])):
        qid = MUNICIPALITY_QID_OVERRIDES.get(municipality["BfsCode"])
        if qid is None:
            qid, _territory_label = resolve_unique(municipality["BfsCode"], wikidata_matches)
        seed_rows.append(
            {
                "level_code": "municipality",
                "admin_code": municipality["BfsCode"],
                "display_name": municipality["Name"],
                "territory_wikidata_id": qid,
                "parent_level_code": "canton",
                "parent_admin_code": CANTON_METADATA_BY_ID[municipality["CantonId"]]["admin_code"],
                "source": "seed.ch_admin_municipality",
            }
        )

    counts = Counter(seed_row["level_code"] for seed_row in seed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Switzerland seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")

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
    municipalities, canton_name_by_id = load_bfs_rows(args.bfs_levels_csv)
    municipality_codes = [row["BfsCode"] for row in municipalities]
    wikidata_matches = load_wikidata_matches(
        municipality_codes,
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = build_seed_rows(municipalities, canton_name_by_id, wikidata_matches)
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Switzerland administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

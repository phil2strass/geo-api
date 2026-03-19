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
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "be_admin_seed.tsv"
REFNIS_2025_URL = "https://statbel.fgov.be/sites/default/files/Over_Statbel_FR/Nomenclaturen/REFNIS_2025.csv"
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-be-admin-seed/1.0 (local maintenance script)"
REGION_CODES = {"02000", "03000", "04000"}
PROVINCE_SPECIAL_CODES = {"20001", "20002"}
EXPECTED_COUNTS = {
    "region": 3,
    "province": 10,
    "arrondissement": 43,
    "municipality": 565,
}
MANUAL_QID_OVERRIDES = {
    # Avoid the historical Flanders item; we want the current Belgian region.
    "02000": "Q9337",
    # Current official arrondissement after the 2019 reform.
    "57000": "Q63020284",
    # Current municipality after the 2025 merger.
    "71072": "Q58780",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Belgium administrative seed used by sync_admin_territory.sh "
            "from the official Statbel REFNIS 2025 nomenclature and Wikidata NIS/INS codes."
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
        help="Number of NIS codes per Wikidata SPARQL request (default: 80).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between Wikidata requests (default: 1.0).",
    )
    return parser.parse_args()


def fetch_text(url: str, *, accept: str | None = None) -> str:
    headers = {"User-Agent": WIKIDATA_USER_AGENT}
    if accept is not None:
        headers["Accept"] = accept
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read().decode("utf-8-sig")


def is_region(code: str) -> bool:
    return code in REGION_CODES


def is_province(code: str) -> bool:
    return code in PROVINCE_SPECIAL_CODES or (code.endswith("0000") and code not in REGION_CODES and code != "01000")


def choose_display_name(
    *,
    code: str,
    current_region_code: str | None,
    language_code: str,
    french_name: str,
    local_name: str,
) -> str:
    if code == "04000":
        return f"{french_name} / {local_name}"
    if language_code == "N":
        return local_name
    if language_code == "F":
        return french_name
    if language_code == "D":
        return local_name
    if language_code == "FN":
        return f"{french_name} / {local_name}"
    if current_region_code == "02000":
        return local_name
    if current_region_code == "04000":
        return f"{french_name} / {local_name}"
    return french_name


def load_refnis_rows() -> list[dict[str, str]]:
    csv_text = fetch_text(REFNIS_2025_URL)
    rows = list(csv.reader(io.StringIO(csv_text), delimiter="|"))
    parsed_rows: list[dict[str, str]] = []
    current_region_code: str | None = None
    current_province_code: str | None = None
    current_arrondissement_code: str | None = None

    for row in rows[1:]:
        if not row or not row[0].strip():
            continue
        code = row[0].strip()
        french_name = row[1].strip()
        language_code = row[2].strip()
        local_name = row[4].strip()
        if code == "01000":
            continue

        if is_region(code):
            level_code = "region"
            parent_level_code = ""
            parent_admin_code = ""
            current_region_code = code
            current_province_code = None
            current_arrondissement_code = None
        elif not language_code and is_province(code):
            level_code = "province"
            parent_level_code = "region"
            parent_admin_code = current_region_code or ""
            current_province_code = code
            current_arrondissement_code = None
        elif not language_code:
            level_code = "arrondissement"
            if current_region_code == "04000":
                parent_level_code = "region"
                parent_admin_code = current_region_code or ""
            else:
                parent_level_code = "province"
                parent_admin_code = current_province_code or ""
            current_arrondissement_code = code
        else:
            level_code = "municipality"
            parent_level_code = "arrondissement"
            parent_admin_code = current_arrondissement_code or ""

        parsed_rows.append(
            {
                "level_code": level_code,
                "admin_code": code,
                "display_name": choose_display_name(
                    code=code,
                    current_region_code=current_region_code,
                    language_code=language_code,
                    french_name=french_name,
                    local_name=local_name,
                ),
                "parent_level_code": parent_level_code,
                "parent_admin_code": parent_admin_code,
                "source": f"seed.be_admin_{level_code}",
            }
        )

    counts = Counter(row["level_code"] for row in parsed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Statbel REFNIS counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")
    return parsed_rows


def build_wikidata_query(codes: list[str]) -> str:
    values = " ".join(f'"{code}"' for code in codes)
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  VALUES ?code {{ {values} }}
  ?item wdt:P1567 ?code .
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "fr,nl,en". }}
}}
""".strip()


def load_wikidata_matches(
    codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, list[tuple[str, str]]]:
    matches: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for start in range(0, len(codes), chunk_size):
        chunk = codes[start : start + chunk_size]
        query = build_wikidata_query(chunk)
        query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query})
        csv_text = fetch_text(query_url, accept="text/csv")
        for row in csv.DictReader(io.StringIO(csv_text)):
            qid = row["item"].rsplit("/", 1)[-1]
            matches[row["code"]].append((qid, row["itemLabel"]))
        if sleep_seconds > 0:
            time.sleep(sleep_seconds)
    return matches


def resolve_qid(code: str, candidates: list[tuple[str, str]]) -> str:
    manual_qid = MANUAL_QID_OVERRIDES.get(code)
    if manual_qid is not None:
        return manual_qid
    if len(candidates) != 1:
        raise RuntimeError(f"Expected exactly one Wikidata match for Belgian code {code}, got {candidates!r}")
    return candidates[0][0]


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
    rows = load_refnis_rows()
    wikidata_matches = load_wikidata_matches(
        [row["admin_code"] for row in rows],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    seed_rows = []
    for row in rows:
        seed_rows.append(
            {
                **row,
                "territory_wikidata_id": resolve_qid(row["admin_code"], wikidata_matches.get(row["admin_code"], [])),
            }
        )
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Belgium administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

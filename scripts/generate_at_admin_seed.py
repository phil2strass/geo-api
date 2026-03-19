#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import sys
import time
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_OUTPUT_PATH = SCRIPT_DIR / "data" / "at_admin_seed.tsv"
MUNICIPALITY_WFS_URL = (
    "https://www.statistik.gv.at/gs-open/GEODATA/ows"
    "?service=WFS&version=1.0.0&request=GetFeature"
    "&typeName=GEODATA:STATISTIK_AUSTRIA_GEM_20260101"
    "&outputFormat=application/json&srsName=EPSG:4326"
)
DISTRICT_WFS_URL = (
    "https://www.statistik.gv.at/gs-open/GEODATA/ows"
    "?service=WFS&version=1.0.0&request=GetFeature"
    "&typeName=GEODATA:STATISTIK_AUSTRIA_POLBEZ_20260101"
    "&outputFormat=application/json&srsName=EPSG:4326"
)
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_ENTITIES_API_URL = "https://www.wikidata.org/w/api.php"
WIKIDATA_USER_AGENT = "geo-api-at-admin-seed/1.0 (local maintenance script)"
EXPECTED_COUNTS = {
    "state": 9,
    "district": 94,
    "municipality": 2092,
}
VIENNA_MUNICIPALITY = {
    "admin_code": "90001",
    "display_name": "Wien",
}
STATE_METADATA_BY_CODE = {
    "1": {
        "display_name": "Burgenland",
        "territory_wikidata_id": "Q43210",
        "territory_name": "Burgenland",
        "territory_type": "region",
    },
    "2": {
        "display_name": "Kärnten",
        "territory_wikidata_id": "Q37985",
        "territory_name": "Carinthia",
        "territory_type": "region",
    },
    "3": {
        "display_name": "Niederösterreich",
        "territory_wikidata_id": "Q42497",
        "territory_name": "Lower Austria",
        "territory_type": "region",
    },
    "4": {
        "display_name": "Oberösterreich",
        "territory_wikidata_id": "Q41967",
        "territory_name": "Upper Austria",
        "territory_type": "region",
    },
    "5": {
        "display_name": "Salzburg",
        "territory_wikidata_id": "Q43325",
        "territory_name": "Salzburg",
        "territory_type": "region",
    },
    "6": {
        "display_name": "Steiermark",
        "territory_wikidata_id": "Q41358",
        "territory_name": "Styria",
        "territory_type": "region",
    },
    "7": {
        "display_name": "Tirol",
        "territory_wikidata_id": "Q42880",
        "territory_name": "Tyrol",
        "territory_type": "region",
    },
    "8": {
        "display_name": "Vorarlberg",
        "territory_wikidata_id": "Q38981",
        "territory_name": "Vorarlberg",
        "territory_type": "region",
    },
    "9": {
        "display_name": "Wien",
        "territory_wikidata_id": "Q1741",
        "territory_name": "Vienna",
        "territory_type": "municipality",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate the curated Austria administrative seed used by sync_admin_territory.sh "
            "from the official Statistik Austria 2026 WFS layers and the Wikidata Austrian GKZ mapping."
        )
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output TSV path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--municipality-wfs",
        default=MUNICIPALITY_WFS_URL,
        help="Official Statistik Austria municipality WFS URL or local path.",
    )
    parser.add_argument(
        "--district-wfs",
        default=DISTRICT_WFS_URL,
        help="Official Statistik Austria district WFS URL or local path.",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=100,
        help="Number of Austrian municipality GKZ codes per Wikidata SPARQL request (default: 100).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=float,
        default=1.0,
        help="Delay between Wikidata requests (default: 1.0).",
    )
    return parser.parse_args()


def fetch_json(source: str) -> dict:
    path = Path(source)
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))

    request = urllib.request.Request(
        source,
        headers={
            "Accept": "application/json",
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.load(response)


def is_vienna_municipal_district(code: str) -> bool:
    return len(code) == 5 and 901 <= int(code[:3]) <= 923


def load_municipality_rows(source: str) -> list[dict[str, str]]:
    payload = fetch_json(source)
    features = payload.get("features", [])
    rows = []
    for feature in features:
        properties = feature["properties"]
        code = properties["g_id"]
        if is_vienna_municipal_district(code):
            continue
        rows.append(
            {
                "admin_code": code,
                "display_name": properties["g_name"],
            }
        )

    rows.append(VIENNA_MUNICIPALITY)
    rows = sorted(rows, key=lambda row: int(row["admin_code"]))

    if len(rows) != EXPECTED_COUNTS["municipality"]:
        raise RuntimeError(
            f"Unexpected Austria municipality count after filtering Vienna districts: "
            f"{len(rows)} != {EXPECTED_COUNTS['municipality']}"
        )

    return rows


def load_district_rows(source: str) -> list[dict[str, str]]:
    payload = fetch_json(source)
    features = payload.get("features", [])
    rows = []
    for feature in features:
        properties = feature["properties"]
        code = properties["g_id"]
        if int(code) > 900:
            continue
        rows.append(
            {
                "admin_code": code,
                "display_name": properties["g_name"],
            }
        )

    if len(rows) != EXPECTED_COUNTS["district"]:
        raise RuntimeError(
            f"Unexpected Austria district count after filtering Vienna municipal districts: "
            f"{len(rows)} != {EXPECTED_COUNTS['district']}"
        )

    return sorted(rows, key=lambda row: int(row["admin_code"]))


def build_wikidata_query(codes: list[str]) -> str:
    return f"""
SELECT ?code ?item ?itemLabel WHERE {{
  ?item wdt:P964 ?code .
  FILTER NOT EXISTS {{ ?item wdt:P576 ?ended }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "en". }}
}}
""".strip()


def fetch_wikidata_bindings(query: str) -> list[dict[str, dict[str, str]]]:
    query_url = WIKIDATA_SPARQL_URL + "?" + urllib.parse.urlencode({"query": query, "format": "json"})
    request = urllib.request.Request(
        query_url,
        headers={
            "Accept": "application/sparql-results+json",
            "User-Agent": WIKIDATA_USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        payload = json.load(response)
    return payload["results"]["bindings"]


def fetch_wikidata_entities(qids: list[str]) -> dict[str, dict]:
    if not qids:
        return {}

    query = urllib.parse.urlencode(
        {
            "action": "wbgetentities",
            "ids": "|".join(qids),
            "props": "labels|claims",
            "languages": "en|de",
            "format": "json",
        }
    )
    request = urllib.request.Request(
        WIKIDATA_ENTITIES_API_URL + "?" + query,
        headers={"User-Agent": WIKIDATA_USER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        payload = json.load(response)
    return payload["entities"]


def claim_entity_ids(entity: dict, property_id: str) -> list[str]:
    values: list[str] = []
    for claim in entity.get("claims", {}).get(property_id, []):
        mainsnak = claim.get("mainsnak", {})
        datavalue = mainsnak.get("datavalue")
        if not datavalue:
            continue
        value = datavalue["value"]
        if isinstance(value, dict) and "id" in value:
            values.append(value["id"])
    return values


def entity_label(entity: dict) -> str:
    labels = entity.get("labels", {})
    if "en" in labels:
        return labels["en"]["value"]
    if "de" in labels:
        return labels["de"]["value"]
    raise RuntimeError(f"Missing usable label for Wikidata entity payload: {entity!r}")


def unique_preserving_order(values: list[str]) -> list[str]:
    return list(dict.fromkeys(values))


def load_wikidata_municipalities(
    municipality_codes: list[str],
    *,
    chunk_size: int,
    sleep_seconds: float,
) -> dict[str, dict[str, str]]:
    by_code: dict[str, dict[str, set[str]]] = defaultdict(
        lambda: {
            "item_qids": set(),
            "item_labels": set(),
        }
    )

    requested_codes = set(municipality_codes)
    for row in fetch_wikidata_bindings(build_wikidata_query(municipality_codes)):
        code = row["code"]["value"]
        if code not in requested_codes:
            continue

        bucket = by_code[code]
        item_qid = row["item"]["value"].rsplit("/", 1)[-1]
        bucket["item_qids"].add(item_qid)
        if "itemLabel" in row:
            bucket["item_labels"].add(row["itemLabel"]["value"])

    if sleep_seconds > 0:
        time.sleep(sleep_seconds)

    resolved: dict[str, dict[str, str]] = {}
    for code in municipality_codes:
        metadata = by_code.get(code)
        if metadata is None:
            raise RuntimeError(f"Missing Wikidata metadata for Austrian GKZ {code}")

        item_qids = metadata["item_qids"]
        item_labels = metadata["item_labels"]

        if len(item_qids) != 1 or len(item_labels) != 1:
            raise RuntimeError(
                f"Expected exactly one municipality Wikidata item for Austrian GKZ {code}, "
                f"got qids={sorted(item_qids)!r}, labels={sorted(item_labels)!r}"
            )

        resolved[code] = {
            "municipality_qid": next(iter(item_qids)),
            "municipality_name": next(iter(item_labels)),
        }

    return resolved


def resolve_district_and_state_metadata(
    municipalities: list[dict[str, str]],
    municipality_metadata: dict[str, dict[str, str]],
) -> dict[str, dict[str, str]]:
    representative_qid_by_district_code: dict[str, str] = {}
    for municipality in municipalities:
        district_code = municipality["admin_code"][:3]
        representative_qid_by_district_code.setdefault(
            district_code,
            municipality_metadata[municipality["admin_code"]]["municipality_qid"],
        )

    entity_cache: dict[str, dict] = {}

    def ensure_entities(qids: set[str]) -> None:
        missing = sorted(qid for qid in qids if qid not in entity_cache)
        for start in range(0, len(missing), 50):
            entity_cache.update(fetch_wikidata_entities(missing[start : start + 50]))

    representative_qids = set(representative_qid_by_district_code.values())
    ensure_entities(representative_qids)

    direct_parent_qids: set[str] = set()
    for qid in representative_qids:
        direct_parent_qids.update(claim_entity_ids(entity_cache[qid], "P131"))
    ensure_entities(direct_parent_qids)

    parent_of_parent_qids: set[str] = set()
    for qid in direct_parent_qids:
        parent_of_parent_qids.update(claim_entity_ids(entity_cache[qid], "P131"))
    ensure_entities(parent_of_parent_qids)

    district_metadata_by_code: dict[str, dict[str, str]] = {}
    for district_code, representative_qid in representative_qid_by_district_code.items():
        representative_entity = entity_cache[representative_qid]
        representative_p31 = set(claim_entity_ids(representative_entity, "P31"))
        representative_p131 = claim_entity_ids(representative_entity, "P131")

        if "Q871419" in representative_p31:
            district_qid = representative_qid
        else:
            district_candidates = unique_preserving_order(
                [
                parent_qid
                for parent_qid in representative_p131
                if "Q871419" in set(claim_entity_ids(entity_cache[parent_qid], "P31"))
                ]
            )
            if len(district_candidates) != 1:
                raise RuntimeError(
                    f"Expected exactly one district parent for Austrian district code {district_code}, "
                    f"got {district_candidates!r}"
                )
            district_qid = district_candidates[0]

        district_entity = entity_cache[district_qid]
        district_metadata_by_code[district_code] = {
            "territory_wikidata_id": district_qid,
            "territory_name": entity_label(district_entity),
            "territory_type": "municipality" if district_qid == representative_qid else "district",
            "parent_admin_code": district_code[:1],
        }

    return district_metadata_by_code


def build_seed_rows(
    municipalities: list[dict[str, str]],
    districts: list[dict[str, str]],
    municipality_metadata: dict[str, dict[str, str]],
    district_metadata_by_code: dict[str, dict[str, str]],
) -> list[dict[str, str]]:
    seed_rows: list[dict[str, str]] = []

    for municipality in municipalities:
        municipality_code = municipality["admin_code"]
        district_code = municipality_code[:3]
        metadata = municipality_metadata[municipality_code]

        seed_rows.append(
            {
                "level_code": "municipality",
                "admin_code": municipality_code,
                "display_name": municipality["display_name"],
                "territory_name": metadata["municipality_name"],
                "territory_wikidata_id": metadata["municipality_qid"],
                "territory_type": "municipality",
                "parent_level_code": "district",
                "parent_admin_code": district_code,
                "source": "seed.at_admin_municipality",
            }
        )

    if len(STATE_METADATA_BY_CODE) != EXPECTED_COUNTS["state"]:
        raise RuntimeError(
            f"Unexpected Austria state metadata count: {len(STATE_METADATA_BY_CODE)} != "
            f"{EXPECTED_COUNTS['state']}"
        )

    for state_code in sorted(STATE_METADATA_BY_CODE, key=int):
        state_metadata = STATE_METADATA_BY_CODE[state_code]
        seed_rows.append(
            {
                "level_code": "state",
                "admin_code": state_code,
                "display_name": state_metadata["display_name"],
                "territory_name": state_metadata["territory_name"],
                "territory_wikidata_id": state_metadata["territory_wikidata_id"],
                "territory_type": state_metadata["territory_type"],
                "parent_level_code": "",
                "parent_admin_code": "",
                "source": "seed.at_admin_state",
            }
        )

    district_names_by_code = {district["admin_code"]: district["display_name"] for district in districts}
    if len(district_names_by_code) != EXPECTED_COUNTS["district"]:
        raise RuntimeError(
            f"Unexpected Austria district count from WFS: {len(district_names_by_code)} != "
            f"{EXPECTED_COUNTS['district']}"
        )

    missing_district_codes = sorted(set(district_names_by_code) - set(district_metadata_by_code))
    if missing_district_codes:
        raise RuntimeError(f"Missing district metadata for Austria district codes: {missing_district_codes!r}")

    for district_code in sorted(district_names_by_code, key=int):
        district_metadata = district_metadata_by_code[district_code]
        seed_rows.append(
            {
                "level_code": "district",
                "admin_code": district_code,
                "display_name": district_names_by_code[district_code],
                "territory_name": district_metadata["territory_name"],
                "territory_wikidata_id": district_metadata["territory_wikidata_id"],
                "territory_type": district_metadata["territory_type"],
                "parent_level_code": "state",
                "parent_admin_code": district_metadata["parent_admin_code"],
                "source": "seed.at_admin_district",
            }
        )

    counts = Counter(seed_row["level_code"] for seed_row in seed_rows)
    if dict(counts) != EXPECTED_COUNTS:
        raise RuntimeError(f"Unexpected Austria seed counts: {dict(counts)!r} != {EXPECTED_COUNTS!r}")

    sort_order = {"state": 1, "district": 2, "municipality": 3}
    return sorted(seed_rows, key=lambda row: (sort_order[row["level_code"]], int(row["admin_code"])))


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
    municipalities = load_municipality_rows(args.municipality_wfs)
    districts = load_district_rows(args.district_wfs)
    municipality_metadata = load_wikidata_municipalities(
        [municipality["admin_code"] for municipality in municipalities],
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    district_metadata_by_code = resolve_district_and_state_metadata(
        municipalities,
        municipality_metadata,
    )
    seed_rows = build_seed_rows(
        municipalities,
        districts,
        municipality_metadata,
        district_metadata_by_code,
    )
    write_seed(seed_rows, args.output)
    print(f"Wrote {len(seed_rows)} Austria administrative rows to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

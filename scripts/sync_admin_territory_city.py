#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import io
import json
import os
import random
import re
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
from collections import Counter
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError


WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_USER_AGENT = "geo-api-admin-territory-city-sync/1.0 (local maintenance script)"
WIKIDATA_LANGUAGES = "fr,en"
WIKIDATA_RETRYABLE_HTTP_CODES = {429, 500, 502, 503, 504}
RELATION_TYPE = "coextensive"
POINT_PATTERN = re.compile(r"Point\(([-+0-9.eE]+)\s+([-+0-9.eE]+)\)$")
SUPPORTED_LOCAL_ADMIN_CITY_CONFIG = {
    "FR": {
        "level_code": "commune",
        "label": "French communes",
    },
    "DE": {
        "level_code": "municipality",
        "label": "German municipalities",
    },
    "ES": {
        "level_code": "municipality",
        "label": "Spanish municipalities",
    },
    "PT": {
        "level_code": "municipality",
        "label": "Portuguese municipalities",
    },
    "BE": {
        "level_code": "municipality",
        "label": "Belgian municipalities",
    },
    "LU": {
        "level_code": "municipality",
        "label": "Luxembourg municipalities",
    },
    "CH": {
        "level_code": "municipality",
        "label": "Swiss municipalities",
    },
    "AT": {
        "level_code": "municipality",
        "label": "Austrian municipalities",
    },
    "NL": {
        "level_code": "municipality",
        "label": "Dutch municipalities",
    },
    "DK": {
        "level_code": "municipality",
        "label": "Danish municipalities",
    },
    "IT": {
        "level_code": "municipality",
        "label": "Italian municipalities",
    },
}
DEFAULT_COUNTRY_ORDER = ["FR", "DE", "ES", "PT", "BE", "LU", "CH", "AT", "NL", "DK", "IT"]


@dataclass(frozen=True)
class LocalAdminRow:
    admin_territory_id: int
    country_id: int
    country_iso: str
    admin_level_code: str
    territory_id: int
    wikidata_id: str
    display_name: str
    territory_name: str
    latitude: str | None
    longitude: str | None
    is_current: bool


@dataclass(frozen=True)
class PopulationCandidate:
    population: int
    population_date: str | None
    rank_priority: int


def parse_positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    if parsed < 1:
        raise argparse.ArgumentTypeError("value must be >= 1")
    return parsed


def parse_non_negative_float(value: str) -> float:
    try:
        parsed = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    if parsed < 0:
        raise argparse.ArgumentTypeError("value must be >= 0")
    return parsed


def parse_args(default_countries: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Populate city and admin_territory_city from coextensive local administrative "
            "units already loaded in admin_territory."
        )
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("LIQUIBASE_DB_HOST", "localhost"),
        help="PostgreSQL host.",
    )
    parser.add_argument(
        "--port",
        type=parse_positive_int,
        default=parse_positive_int(os.environ.get("LIQUIBASE_DB_PORT", "55432")),
        help="PostgreSQL port.",
    )
    parser.add_argument(
        "--dbname",
        default=os.environ.get("LIQUIBASE_DB_NAME", "geo2"),
        help="PostgreSQL database name.",
    )
    parser.add_argument(
        "--user",
        default=os.environ.get("LIQUIBASE_DB_USER", "geo"),
        help="PostgreSQL user.",
    )
    parser.add_argument(
        "--password",
        default=os.environ.get("LIQUIBASE_DB_PASSWORD", "geo"),
        help="PostgreSQL password.",
    )
    parser.add_argument(
        "--country",
        action="append",
        dest="countries",
        help=(
            "ISO2 country code to sync. Repeat the option to target several countries. "
            f"Defaults to: {', '.join(default_countries or DEFAULT_COUNTRY_ORDER)}."
        ),
    )
    parser.add_argument(
        "--chunk-size",
        type=parse_positive_int,
        default=120,
        help="Number of QIDs per Wikidata request (default: 120).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=parse_non_negative_float,
        default=0.2,
        help="Delay between Wikidata requests (default: 0.2).",
    )
    parser.add_argument(
        "--limit",
        type=parse_positive_int,
        help="Optional row limit for debugging a smaller set of admin territories.",
    )
    return parser.parse_args()


def normalize_requested_countries(
    requested_countries: list[str] | None,
    default_countries: list[str] | None = None,
) -> list[str]:
    countries = requested_countries or default_countries or DEFAULT_COUNTRY_ORDER
    normalized = [country.strip().upper() for country in countries if country.strip()]
    if not normalized:
        raise ValueError("At least one country must be selected.")

    unsupported = sorted(set(normalized) - set(SUPPORTED_LOCAL_ADMIN_CITY_CONFIG))
    if unsupported:
        raise ValueError(
            "Unsupported country code(s) for city sync: " + ", ".join(unsupported)
        )

    return list(dict.fromkeys(normalized))


def run_psql_csv_query(args: argparse.Namespace, sql: str) -> list[dict[str, str]]:
    env = os.environ.copy()
    env["PGPASSWORD"] = args.password
    command = [
        "psql",
        "-v",
        "ON_ERROR_STOP=1",
        "-h",
        args.host,
        "-p",
        str(args.port),
        "-U",
        args.user,
        "-d",
        args.dbname,
        "-c",
        f"COPY ({sql}) TO STDOUT WITH CSV HEADER",
    ]
    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    return list(csv.DictReader(io.StringIO(result.stdout)))


def run_psql_file(args: argparse.Namespace, sql_path: Path) -> None:
    env = os.environ.copy()
    env["PGPASSWORD"] = args.password
    subprocess.run(
        [
            "psql",
            "-v",
            "ON_ERROR_STOP=1",
            "-h",
            args.host,
            "-p",
            str(args.port),
            "-U",
            args.user,
            "-d",
            args.dbname,
            "-f",
            str(sql_path),
        ],
        check=True,
        env=env,
    )


def requested_pairs_sql(countries: list[str]) -> str:
    return ", ".join(
        f"({sql_quote(country)}, {sql_quote(SUPPORTED_LOCAL_ADMIN_CITY_CONFIG[country]['level_code'])})"
        for country in countries
    )


def load_local_admin_units(
    args: argparse.Namespace,
    countries: list[str],
) -> list[LocalAdminRow]:
    limit_clause = f"LIMIT {args.limit}" if args.limit else ""
    rows = run_psql_csv_query(
        args,
        f"""
        WITH requested(country_iso, level_code) AS (
            VALUES {requested_pairs_sql(countries)}
        )
        SELECT
            at.id AS admin_territory_id,
            at.country_id,
            c.iso_code AS country_iso,
            cal.code AS admin_level_code,
            at.territory_id,
            t.wikidata_id,
            at.display_name,
            t.name AS territory_name,
            t.latitude::TEXT AS latitude,
            t.longitude::TEXT AS longitude,
            at.is_current
        FROM admin_territory at
        JOIN country_admin_level cal ON cal.id = at.admin_level_id
        JOIN country c ON c.id = at.country_id
        JOIN territory t ON t.id = at.territory_id
        JOIN requested r
          ON r.country_iso = c.iso_code
         AND r.level_code = cal.code
        WHERE at.is_current
          AND t.wikidata_id IS NOT NULL
        ORDER BY c.iso_code, at.admin_code, at.id
        {limit_clause}
        """,
    )
    return [
        LocalAdminRow(
            admin_territory_id=int(row["admin_territory_id"]),
            country_id=int(row["country_id"]),
            country_iso=row["country_iso"],
            admin_level_code=row["admin_level_code"],
            territory_id=int(row["territory_id"]),
            wikidata_id=row["wikidata_id"],
            display_name=row["display_name"],
            territory_name=row["territory_name"],
            latitude=null_if_empty(row["latitude"]),
            longitude=null_if_empty(row["longitude"]),
            is_current=parse_bool(row["is_current"]),
        )
        for row in rows
    ]


def parse_bool(value: str) -> bool:
    return value.lower() in {"t", "true", "1", "yes", "y"}


def build_base_query(qids: list[str]) -> str:
    values = " ".join(f"wd:{qid}" for qid in qids)
    return f"""
SELECT ?item ?itemLabel ?itemDescription ?coord ?area ?inception ?dissolved ?website WHERE {{
  VALUES ?item {{ {values} }}
  OPTIONAL {{ ?item wdt:P625 ?coord . }}
  OPTIONAL {{ ?item wdt:P2046 ?area . }}
  OPTIONAL {{ ?item wdt:P571 ?inception . }}
  OPTIONAL {{ ?item wdt:P576 ?dissolved . }}
  OPTIONAL {{ ?item wdt:P856 ?website . }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "{WIKIDATA_LANGUAGES}". }}
}}
""".strip()


def build_population_query(qids: list[str]) -> str:
    values = " ".join(f"wd:{qid}" for qid in qids)
    return f"""
SELECT ?item ?population ?populationDate ?rank WHERE {{
  VALUES ?item {{ {values} }}
  ?item p:P1082 ?populationStatement .
  ?populationStatement ps:P1082 ?population .
  OPTIONAL {{ ?populationStatement pq:P585 ?populationDate . }}
  ?populationStatement wikibase:rank ?rank .
  FILTER (?rank != wikibase:DeprecatedRank)
}}
""".strip()


def fetch_wikidata_json(query: str, max_attempts: int = 5) -> dict[str, Any]:
    params = urllib.parse.urlencode({"format": "json", "query": query})
    url = f"{WIKIDATA_SPARQL_URL}?{params}"
    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        request = urllib.request.Request(
            url,
            headers={
                "Accept": "application/sparql-results+json",
                "User-Agent": WIKIDATA_USER_AGENT,
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as exc:
            last_error = exc
            if exc.code not in WIKIDATA_RETRYABLE_HTTP_CODES:
                raise
            retry_after = parse_retry_after_seconds(exc)
            sleep_seconds = (
                retry_after
                if retry_after is not None
                else min((2 ** attempt) + random.random(), 30.0)
            )
            print(
                f"Wikidata retry {attempt}/{max_attempts} http={exc.code} sleep={sleep_seconds:.1f}s"
            )
            time.sleep(sleep_seconds)
        except (TimeoutError, URLError) as exc:
            last_error = exc
            sleep_seconds = min((2 ** attempt) + random.random(), 30.0)
            print(
                f"Wikidata retry {attempt}/{max_attempts} error={exc} sleep={sleep_seconds:.1f}s"
            )
            time.sleep(sleep_seconds)
    raise RuntimeError("Wikidata query failed after retries") from last_error


def parse_retry_after_seconds(exc: HTTPError) -> int | None:
    if exc.headers is None:
        return None
    value = exc.headers.get("Retry-After")
    if value is None:
        return None
    value = value.strip()
    if value.isdigit():
        return int(value)
    return None


def iter_bindings(payload: dict[str, Any]) -> list[dict[str, dict[str, str]]]:
    return payload.get("results", {}).get("bindings", [])


def qid_from_binding(value: str) -> str:
    return value.rsplit("/", 1)[-1]


def null_if_empty(value: str | None) -> str | None:
    if value is None:
        return None
    stripped = value.strip()
    return stripped or None


def parse_decimal(value: str | None) -> str | None:
    if value is None:
        return None
    try:
        decimal_value = Decimal(value)
    except InvalidOperation:
        return None
    return format(decimal_value, "f")


def parse_area_km2(value: str | None) -> str | None:
    normalized = parse_decimal(value)
    if normalized is None:
        return None
    try:
        raw_area = Decimal(normalized)
    except InvalidOperation:
        return None
    # Wikidata P2046 is not perfectly normalized in practice for these local units:
    # some values are already expressed in km2, while others appear in m2.
    # Local administrative units cannot plausibly exceed 100000 km2, so treat
    # larger values as m2 and convert them.
    if raw_area > Decimal("100000"):
        raw_area = raw_area / Decimal("1000000")
    return format(raw_area, "f")


def parse_population(value: str | None) -> int | None:
    normalized = parse_decimal(value)
    if normalized is None:
        return None
    try:
        return int(Decimal(normalized))
    except (InvalidOperation, ValueError):
        return None


def parse_date(value: str | None) -> str | None:
    if value is None:
        return None
    candidate = value.split("T", 1)[0].lstrip("+")
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", candidate):
        return candidate
    return None


def parse_point(value: str | None) -> tuple[str | None, str | None]:
    if value is None:
        return (None, None)
    point_index = value.rfind("Point(")
    if point_index == -1:
        return (None, None)
    match = POINT_PATTERN.search(value[point_index:])
    if not match:
        return (None, None)
    longitude = parse_decimal(match.group(1))
    latitude = parse_decimal(match.group(2))
    return (latitude, longitude)


def rank_priority(value: str | None) -> int:
    if value is None:
        return 0
    rank_name = value.rsplit("/", 1)[-1]
    if rank_name == "PreferredRank":
        return 2
    if rank_name == "NormalRank":
        return 1
    return 0


def choose_population(candidates: list[PopulationCandidate]) -> PopulationCandidate | None:
    if not candidates:
        return None
    return max(
        candidates,
        key=lambda candidate: (
            candidate.population_date is not None,
            candidate.population_date or "",
            candidate.rank_priority,
            candidate.population,
        ),
    )


def load_wikidata_metadata(
    qids: list[str], *, chunk_size: int, sleep_seconds: float
) -> dict[str, dict[str, str | int | None]]:
    metadata: dict[str, dict[str, str | int | None]] = {
        qid: {
            "name": None,
            "description": None,
            "latitude": None,
            "longitude": None,
            "area_km2": None,
            "inception_date": None,
            "dissolved_date": None,
            "website": None,
            "population": None,
            "population_date": None,
        }
        for qid in qids
    }

    for start in range(0, len(qids), chunk_size):
        chunk = qids[start : start + chunk_size]
        print(f"Wikidata batch {start + 1}-{start + len(chunk)} / {len(qids)}")
        base_payload = fetch_wikidata_json(build_base_query(chunk))
        for row in iter_bindings(base_payload):
            item_value = row.get("item", {}).get("value")
            if not item_value:
                continue
            qid = qid_from_binding(item_value)
            entry = metadata[qid]
            label = binding_value(row, "itemLabel")
            description = binding_value(row, "itemDescription")
            area = parse_area_km2(binding_value(row, "area"))
            inception_date = parse_date(binding_value(row, "inception"))
            dissolved_date = parse_date(binding_value(row, "dissolved"))
            website = binding_value(row, "website")
            latitude, longitude = parse_point(binding_value(row, "coord"))

            if label and not entry["name"]:
                entry["name"] = label
            if description and not entry["description"]:
                entry["description"] = description
            if latitude and not entry["latitude"]:
                entry["latitude"] = latitude
            if longitude and not entry["longitude"]:
                entry["longitude"] = longitude
            if area and not entry["area_km2"]:
                entry["area_km2"] = area
            if inception_date and not entry["inception_date"]:
                entry["inception_date"] = inception_date
            if dissolved_date and not entry["dissolved_date"]:
                entry["dissolved_date"] = dissolved_date
            if website and not entry["website"]:
                entry["website"] = website

        population_candidates: dict[str, list[PopulationCandidate]] = {
            qid: [] for qid in chunk
        }
        population_payload = fetch_wikidata_json(build_population_query(chunk))
        for row in iter_bindings(population_payload):
            item_value = row.get("item", {}).get("value")
            if not item_value:
                continue
            qid = qid_from_binding(item_value)
            population = parse_population(binding_value(row, "population"))
            if population is None:
                continue
            population_candidates[qid].append(
                PopulationCandidate(
                    population=population,
                    population_date=parse_date(binding_value(row, "populationDate")),
                    rank_priority=rank_priority(binding_value(row, "rank")),
                )
            )

        for qid, candidates in population_candidates.items():
            chosen = choose_population(candidates)
            if chosen is None:
                continue
            entry = metadata[qid]
            entry["population"] = chosen.population
            entry["population_date"] = chosen.population_date

        if sleep_seconds > 0:
            time.sleep(sleep_seconds)

    return metadata


def binding_value(row: dict[str, dict[str, str]], key: str) -> str | None:
    binding = row.get(key)
    if not binding:
        return None
    return null_if_empty(binding.get("value"))


def write_stage_csv(path: Path, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def apply_sync(
    args: argparse.Namespace,
    city_rows: list[dict[str, Any]],
    relation_rows: list[dict[str, Any]],
) -> None:
    with tempfile.TemporaryDirectory(prefix="admin-territory-city-") as tmp_dir:
        tmp_path = Path(tmp_dir)
        city_csv = tmp_path / "city_stage.csv"
        relation_csv = tmp_path / "admin_territory_city_stage.csv"
        sql_file = tmp_path / "sync.sql"

        write_stage_csv(
            city_csv,
            [
                "country_id",
                "territory_id",
                "wikidata_id",
                "name",
                "description",
                "latitude",
                "longitude",
                "population",
                "population_date",
                "area_km2",
                "inception_date",
                "dissolved_date",
                "website",
                "is_current",
                "source",
            ],
            city_rows,
        )
        write_stage_csv(
            relation_csv,
            ["admin_territory_id", "territory_id", "relation_type", "source"],
            relation_rows,
        )

        sql_file.write_text(
            f"""
BEGIN;

CREATE TEMP TABLE city_stage (
    country_id BIGINT NOT NULL,
    territory_id BIGINT NOT NULL,
    wikidata_id VARCHAR(32) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    latitude TEXT,
    longitude TEXT,
    population TEXT,
    population_date DATE,
    area_km2 TEXT,
    inception_date DATE,
    dissolved_date DATE,
    website TEXT,
    is_current BOOLEAN NOT NULL,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

\\copy city_stage (country_id, territory_id, wikidata_id, name, description, latitude, longitude, population, population_date, area_km2, inception_date, dissolved_date, website, is_current, source) FROM {sql_quote(str(city_csv))} WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE admin_territory_city_stage (
    admin_territory_id BIGINT NOT NULL,
    territory_id BIGINT NOT NULL,
    relation_type VARCHAR(32) NOT NULL,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

\\copy admin_territory_city_stage (admin_territory_id, territory_id, relation_type, source) FROM {sql_quote(str(relation_csv))} WITH (FORMAT csv, HEADER true)

UPDATE city c
SET
    country_id = s.country_id,
    territory_id = s.territory_id,
    wikidata_id = s.wikidata_id,
    name = s.name,
    description = NULLIF(s.description, ''),
    latitude = CASE WHEN NULLIF(s.latitude, '') IS NULL THEN NULL ELSE CAST(s.latitude AS NUMERIC(9, 6)) END,
    longitude = CASE WHEN NULLIF(s.longitude, '') IS NULL THEN NULL ELSE CAST(s.longitude AS NUMERIC(9, 6)) END,
    population = CASE WHEN NULLIF(s.population, '') IS NULL THEN NULL ELSE CAST(s.population AS BIGINT) END,
    population_date = s.population_date,
    area_km2 = CASE WHEN NULLIF(s.area_km2, '') IS NULL THEN NULL ELSE CAST(s.area_km2 AS NUMERIC(12, 3)) END,
    inception_date = s.inception_date,
    dissolved_date = s.dissolved_date,
    website = NULLIF(s.website, ''),
    is_current = s.is_current,
    source = s.source
FROM city_stage s
WHERE c.wikidata_id = s.wikidata_id
   OR c.territory_id = s.territory_id;

INSERT INTO city (
    country_id,
    territory_id,
    wikidata_id,
    name,
    description,
    latitude,
    longitude,
    population,
    population_date,
    area_km2,
    inception_date,
    dissolved_date,
    website,
    is_current,
    source
)
SELECT
    s.country_id,
    s.territory_id,
    s.wikidata_id,
    s.name,
    NULLIF(s.description, ''),
    CASE WHEN NULLIF(s.latitude, '') IS NULL THEN NULL ELSE CAST(s.latitude AS NUMERIC(9, 6)) END,
    CASE WHEN NULLIF(s.longitude, '') IS NULL THEN NULL ELSE CAST(s.longitude AS NUMERIC(9, 6)) END,
    CASE WHEN NULLIF(s.population, '') IS NULL THEN NULL ELSE CAST(s.population AS BIGINT) END,
    s.population_date,
    CASE WHEN NULLIF(s.area_km2, '') IS NULL THEN NULL ELSE CAST(s.area_km2 AS NUMERIC(12, 3)) END,
    s.inception_date,
    s.dissolved_date,
    NULLIF(s.website, ''),
    s.is_current,
    s.source
FROM city_stage s
LEFT JOIN city c
       ON c.wikidata_id = s.wikidata_id
      OR c.territory_id = s.territory_id
WHERE c.id IS NULL;

INSERT INTO admin_territory_city (
    admin_territory_id,
    city_id,
    relation_type,
    source
)
SELECT
    s.admin_territory_id,
    c.id,
    s.relation_type,
    s.source
FROM admin_territory_city_stage s
JOIN city c ON c.territory_id = s.territory_id
ON CONFLICT ON CONSTRAINT uq_admin_territory_city_relation
DO UPDATE
SET
    city_id = EXCLUDED.city_id,
    source = EXCLUDED.source;

COMMIT;
""".strip()
            + "\n",
            encoding="utf-8",
        )

        run_psql_file(args, sql_file)


def city_source(row: LocalAdminRow) -> str:
    return (
        "wikidata.admin_territory_city."
        f"{row.country_iso.lower()}.{row.admin_level_code}"
    )


def relation_source(row: LocalAdminRow) -> str:
    return city_source(row) + ".coextensive"


def build_city_rows(
    local_units: list[LocalAdminRow],
    metadata: dict[str, dict[str, str | int | None]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for unit in local_units:
        wd = metadata.get(unit.wikidata_id, {})
        name = unit.display_name or unit.territory_name or as_text(wd.get("name"))
        latitude = as_text(wd.get("latitude")) or unit.latitude
        longitude = as_text(wd.get("longitude")) or unit.longitude
        rows.append(
            {
                "country_id": unit.country_id,
                "territory_id": unit.territory_id,
                "wikidata_id": unit.wikidata_id,
                "name": name,
                "description": as_text(wd.get("description")) or "",
                "latitude": latitude or "",
                "longitude": longitude or "",
                "population": as_text(wd.get("population")) or "",
                "population_date": as_text(wd.get("population_date")) or "",
                "area_km2": as_text(wd.get("area_km2")) or "",
                "inception_date": as_text(wd.get("inception_date")) or "",
                "dissolved_date": as_text(wd.get("dissolved_date")) or "",
                "website": as_text(wd.get("website")) or "",
                "is_current": "true" if unit.is_current else "false",
                "source": city_source(unit),
            }
        )
    return rows


def build_relation_rows(local_units: list[LocalAdminRow]) -> list[dict[str, Any]]:
    return [
        {
            "admin_territory_id": unit.admin_territory_id,
            "territory_id": unit.territory_id,
            "relation_type": RELATION_TYPE,
            "source": relation_source(unit),
        }
        for unit in local_units
    ]


def as_text(value: Any) -> str | None:
    if value is None:
        return None
    return str(value)


def summarize_local_units(local_units: list[LocalAdminRow]) -> str:
    counts = Counter(unit.country_iso for unit in local_units)
    return ", ".join(f"{country} {counts[country]}" for country in sorted(counts))


def main(default_countries: list[str] | None = None) -> None:
    args = parse_args(default_countries=default_countries)
    countries = normalize_requested_countries(args.countries, default_countries)
    local_units = load_local_admin_units(args, countries)
    if not local_units:
        print("No matching current admin territories found for city sync.")
        return

    print(
        "Loaded "
        f"{len(local_units)} local administrative units from admin_territory "
        f"({summarize_local_units(local_units)})."
    )
    qids = list(dict.fromkeys(unit.wikidata_id for unit in local_units))
    metadata = load_wikidata_metadata(
        qids,
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )

    city_rows = build_city_rows(local_units, metadata)
    relation_rows = build_relation_rows(local_units)
    apply_sync(args, city_rows, relation_rows)
    print(
        f"Synced {len(city_rows)} city rows and {len(relation_rows)} admin_territory_city links."
    )


if __name__ == "__main__":
    main()

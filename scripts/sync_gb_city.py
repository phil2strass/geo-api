#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from sync_admin_territory_city import (
    WIKIDATA_LANGUAGES,
    as_text,
    binding_value,
    fetch_wikidata_json,
    iter_bindings,
    load_wikidata_metadata,
    parse_non_negative_float,
    parse_positive_int,
    qid_from_binding,
    run_psql_csv_query,
    run_psql_file,
    sql_quote,
    write_stage_csv,
)


GB_COUNTRY_QID = "Q145"
GB_CONSTITUENT_COUNTRY_QIDS = ("Q21", "Q22", "Q25", "Q26")
GB_SETTLEMENT_CLASS_QIDS = ("Q515", "Q3957")
GB_CITY_SOURCE = "wikidata.city.gb.city_or_town"
LEGACY_GB_CITY_SOURCE = "wikidata.admin_territory_city.gb.local_authority_district"
LEGACY_GB_RELATION_SOURCE_PREFIX = "wikidata.admin_territory_city.gb."


@dataclass(frozen=True)
class GbSettlementRow:
    wikidata_id: str
    name: str | None
    description: str | None


@dataclass(frozen=True)
class TerritoryLookupRow:
    territory_id: int
    name: str
    latitude: str | None
    longitude: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Populate city with real United Kingdom urban settlements (Wikidata city/town), "
            "replacing the temporary coextensive local-authority projection."
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
        "--chunk-size",
        type=parse_positive_int,
        default=120,
        help="Number of QIDs per Wikidata metadata request (default: 120).",
    )
    parser.add_argument(
        "--sleep-seconds",
        type=parse_non_negative_float,
        default=0.2,
        help="Delay between Wikidata requests (default: 0.2).",
    )
    parser.add_argument(
        "--territory-chunk-size",
        type=parse_positive_int,
        default=400,
        help="Number of QIDs per PostgreSQL territory lookup chunk (default: 400).",
    )
    return parser.parse_args()


def build_settlement_query() -> str:
    classes = " ".join(f"wd:{qid}" for qid in GB_SETTLEMENT_CLASS_QIDS)
    constituent_countries = " ".join(f"wd:{qid}" for qid in GB_CONSTITUENT_COUNTRY_QIDS)
    return f"""
SELECT DISTINCT ?item ?itemLabel ?itemDescription WHERE {{
  VALUES ?settlementClass {{ {classes} }}
  VALUES ?constituentCountry {{ {constituent_countries} }}
  ?item wdt:P31 ?settlementClass .
  ?item wdt:P17 wd:{GB_COUNTRY_QID} .
  ?item wdt:P131* ?constituentCountry .
  FILTER NOT EXISTS {{ ?item wdt:P576 ?dissolved . }}
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "{WIKIDATA_LANGUAGES}". }}
}}
ORDER BY ?item
""".strip()


def load_gb_settlements() -> list[GbSettlementRow]:
    payload = fetch_wikidata_json(build_settlement_query())
    settlements: dict[str, GbSettlementRow] = {}
    for row in iter_bindings(payload):
        item_value = binding_value(row, "item")
        if not item_value:
            continue
        qid = qid_from_binding(item_value)
        settlements[qid] = GbSettlementRow(
            wikidata_id=qid,
            name=binding_value(row, "itemLabel"),
            description=binding_value(row, "itemDescription"),
        )
    return [settlements[qid] for qid in sorted(settlements)]


def load_country_id(args: argparse.Namespace) -> int:
    rows = run_psql_csv_query(
        args,
        """
        SELECT id AS country_id
        FROM country
        WHERE iso_code = 'GB'
        """,
    )
    if len(rows) != 1:
        raise RuntimeError(f"Expected one GB country row, got {len(rows)}")
    return int(rows[0]["country_id"])


def load_territory_lookup(
    args: argparse.Namespace,
    qids: list[str],
    *,
    chunk_size: int,
) -> dict[str, TerritoryLookupRow]:
    lookup: dict[str, TerritoryLookupRow] = {}
    for start in range(0, len(qids), chunk_size):
        chunk = qids[start : start + chunk_size]
        if not chunk:
            continue
        quoted_qids = ", ".join(sql_quote(qid) for qid in chunk)
        rows = run_psql_csv_query(
            args,
            f"""
            SELECT
                id AS territory_id,
                wikidata_id,
                name,
                latitude::TEXT AS latitude,
                longitude::TEXT AS longitude
            FROM territory
            WHERE country_id = (
                SELECT id
                FROM country
                WHERE iso_code = 'GB'
            )
              AND wikidata_id IN ({quoted_qids})
            ORDER BY wikidata_id, id
            """,
        )
        for row in rows:
            qid = row["wikidata_id"]
            if qid in lookup:
                continue
            lookup[qid] = TerritoryLookupRow(
                territory_id=int(row["territory_id"]),
                name=row["name"],
                latitude=row["latitude"] or None,
                longitude=row["longitude"] or None,
            )
    return lookup


def build_city_rows(
    *,
    country_id: int,
    settlements: list[GbSettlementRow],
    metadata: dict[str, dict[str, str | int | None]],
    territory_lookup: dict[str, TerritoryLookupRow],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for settlement in settlements:
        territory = territory_lookup.get(settlement.wikidata_id)
        wd = metadata.get(settlement.wikidata_id, {})
        name = as_text(wd.get("name")) or settlement.name or (territory.name if territory else None)
        if not name:
            raise RuntimeError(f"Missing display name for {settlement.wikidata_id}")
        latitude = as_text(wd.get("latitude")) or (territory.latitude if territory else None)
        longitude = as_text(wd.get("longitude")) or (territory.longitude if territory else None)
        rows.append(
            {
                "country_id": country_id,
                "territory_id": territory.territory_id if territory else "",
                "wikidata_id": settlement.wikidata_id,
                "name": name,
                "description": as_text(wd.get("description")) or settlement.description or "",
                "latitude": latitude or "",
                "longitude": longitude or "",
                "population": as_text(wd.get("population")) or "",
                "population_date": as_text(wd.get("population_date")) or "",
                "area_km2": as_text(wd.get("area_km2")) or "",
                "inception_date": as_text(wd.get("inception_date")) or "",
                "dissolved_date": as_text(wd.get("dissolved_date")) or "",
                "website": as_text(wd.get("website")) or "",
                "is_current": "true",
                "source": GB_CITY_SOURCE,
            }
        )
    return rows


def apply_sync(args: argparse.Namespace, *, country_id: int, city_rows: list[dict[str, Any]]) -> None:
    with tempfile.TemporaryDirectory(prefix="gb-city-sync-") as tmp_dir:
        tmp_path = Path(tmp_dir)
        city_csv = tmp_path / "city_stage.csv"
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

        sql_file.write_text(
            f"""
BEGIN;

CREATE TEMP TABLE city_stage (
    country_id BIGINT NOT NULL,
    territory_id BIGINT,
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

DELETE FROM admin_territory_city
WHERE source LIKE {sql_quote(LEGACY_GB_RELATION_SOURCE_PREFIX + "%")};

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
WHERE c.country_id = {country_id}
  AND (
      c.wikidata_id = s.wikidata_id
      OR (s.territory_id IS NOT NULL AND c.territory_id = s.territory_id)
  );

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
       ON c.country_id = {country_id}
      AND (
          c.wikidata_id = s.wikidata_id
          OR (s.territory_id IS NOT NULL AND c.territory_id = s.territory_id)
      )
WHERE c.id IS NULL;

DELETE FROM city c
WHERE c.country_id = {country_id}
  AND c.source IN ({sql_quote(LEGACY_GB_CITY_SOURCE)}, {sql_quote(GB_CITY_SOURCE)})
  AND NOT EXISTS (
      SELECT 1
      FROM city_stage s
      WHERE s.wikidata_id = c.wikidata_id
  );

COMMIT;
""".strip()
            + "\n",
            encoding="utf-8",
        )

        run_psql_file(args, sql_file)


def load_city_stats(args: argparse.Namespace) -> dict[str, int]:
    rows = run_psql_csv_query(
        args,
        """
        SELECT
            count(*) AS city_count,
            count(*) FILTER (WHERE territory_id IS NOT NULL) AS linked_territory_count,
            count(*) FILTER (WHERE wikidata_id IS NULL) AS null_wikidata_count
        FROM city
        WHERE country_id = (
            SELECT id
            FROM country
            WHERE iso_code = 'GB'
        )
        """,
    )
    if len(rows) != 1:
        raise RuntimeError(f"Expected one GB city stats row, got {len(rows)}")
    row = rows[0]
    return {
        "city_count": int(row["city_count"]),
        "linked_territory_count": int(row["linked_territory_count"]),
        "null_wikidata_count": int(row["null_wikidata_count"]),
    }


def main() -> int:
    args = parse_args()
    settlements = load_gb_settlements()
    if not settlements:
        print("No current GB settlements found in Wikidata.")
        return 0

    print(f"Loaded {len(settlements)} GB city/town settlements from Wikidata.")
    country_id = load_country_id(args)
    qids = [settlement.wikidata_id for settlement in settlements]
    territory_lookup = load_territory_lookup(
        args,
        qids,
        chunk_size=args.territory_chunk_size,
    )
    metadata = load_wikidata_metadata(
        qids,
        chunk_size=args.chunk_size,
        sleep_seconds=args.sleep_seconds,
    )
    city_rows = build_city_rows(
        country_id=country_id,
        settlements=settlements,
        metadata=metadata,
        territory_lookup=territory_lookup,
    )
    apply_sync(args, country_id=country_id, city_rows=city_rows)
    stats = load_city_stats(args)
    print(
        "Synced "
        f"{stats['city_count']} GB city rows "
        f"({sum(1 for row in city_rows if row['territory_id'])} territory-linked in stage, "
        f"{stats['linked_territory_count']} territory-linked in database)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

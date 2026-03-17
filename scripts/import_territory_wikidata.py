#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
from typing import TYPE_CHECKING, Any

from stream_territory_wikidata_sql import STAGE_COLUMNS, iter_rows, parse_sql_tuple

if TYPE_CHECKING:
    import psycopg

ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_SQL = ROOT_DIR / "liquibase/changelog/18-load-territory-from-wikidata.sql"
IMPORT_STATE_TABLE = "bulk_import_state"
IMPORT_KEY = "territory_wikidata"
STAGE_TABLE = "territory_wikidata_stage"


def parse_positive_int(value: str) -> int:
    try:
        parsed = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc

    if parsed < 1:
        raise argparse.ArgumentTypeError("value must be >= 1")

    return parsed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import the standalone data migration 18 into territory."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path(
            os.environ.get("LIQUIBASE_TERRITORY_SOURCE_SQL", str(DEFAULT_SOURCE_SQL))
        ),
        help="Path to the generated 18-load-territory-from-wikidata.sql file.",
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
        "--format-version",
        type=parse_positive_int,
        default=parse_positive_int(
            os.environ.get("LIQUIBASE_TERRITORY_IMPORT_FORMAT_VERSION", "1")
        ),
        help="Logical format version used to invalidate import state.",
    )
    return parser.parse_args()


def compute_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_import_state_table(cur: Any) -> None:
    cur.execute(
        f"""
        CREATE TABLE IF NOT EXISTS {IMPORT_STATE_TABLE} (
            import_key TEXT PRIMARY KEY,
            source_sha256 TEXT NOT NULL,
            format_version INTEGER NOT NULL,
            loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )


def territory_table_exists(cur: Any) -> bool:
    cur.execute("SELECT to_regclass('public.territory') IS NOT NULL")
    row = cur.fetchone()
    return bool(row and row[0])


def import_is_current(
    cur: Any, source_sha256: str, format_version: int
) -> bool:
    cur.execute("SELECT EXISTS (SELECT 1 FROM territory LIMIT 1)")
    territory_has_rows = bool(cur.fetchone()[0])
    if not territory_has_rows:
        return False

    cur.execute(
        f"""
        SELECT source_sha256, format_version
        FROM {IMPORT_STATE_TABLE}
        WHERE import_key = %s
        """,
        (IMPORT_KEY,),
    )
    row = cur.fetchone()
    return bool(row and row[0] == source_sha256 and row[1] == format_version)


def recreate_stage_table(cur: Any) -> None:
    cur.execute(f"DROP TABLE IF EXISTS {STAGE_TABLE}")
    cur.execute(
        f"""
        CREATE UNLOGGED TABLE {STAGE_TABLE} (
            wikidata_id TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            country_iso TEXT NOT NULL,
            parent_wikidata_id TEXT,
            telephone_country_code TEXT,
            local_dialing_code TEXT,
            latitude TEXT,
            longitude TEXT
        )
        """
    )


def load_stage_table(
    cur: Any,
    source: Path,
) -> None:
    copy_sql = f"COPY {STAGE_TABLE} ({', '.join(STAGE_COLUMNS)}) FROM STDIN"

    with cur.copy(copy_sql) as copy:
        for line_number, row in iter_rows(source):
            copy.write_row(parse_sql_tuple(row, line_number))


def merge_stage_into_territory(
    cur: Any, source_sha256: str, format_version: int
) -> None:
    cur.execute("SET client_min_messages = warning")
    cur.execute("SET statement_timeout = 0")
    cur.execute(f"ANALYZE {STAGE_TABLE}")
    cur.execute(
        f"""
        INSERT INTO territory (
            wikidata_id,
            name,
            type,
            country_id,
            parent_id,
            telephone_country_code,
            local_dialing_code,
            latitude,
            longitude
        )
        SELECT
            NULLIF(d.wikidata_id, ''),
            NULLIF(d.name, ''),
            NULLIF(d.type, ''),
            c.id,
            NULL,
            NULLIF(d.telephone_country_code, ''),
            NULLIF(d.local_dialing_code, ''),
            CASE
                WHEN NULLIF(d.latitude, '') IS NULL THEN NULL
                ELSE CAST(d.latitude AS NUMERIC(9, 6))
            END,
            CASE
                WHEN NULLIF(d.longitude, '') IS NULL THEN NULL
                ELSE CAST(d.longitude AS NUMERIC(9, 6))
            END
        FROM {STAGE_TABLE} d
        JOIN country c ON c.iso_code = NULLIF(d.country_iso, '')
        ON CONFLICT (wikidata_id) DO UPDATE
        SET
            name = EXCLUDED.name,
            type = EXCLUDED.type,
            country_id = EXCLUDED.country_id,
            telephone_country_code = EXCLUDED.telephone_country_code,
            local_dialing_code = EXCLUDED.local_dialing_code,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude
        """
    )
    cur.execute(
        f"""
        UPDATE territory t
        SET parent_id = p.id
        FROM {STAGE_TABLE} d
        JOIN territory p ON p.wikidata_id = NULLIF(d.parent_wikidata_id, '')
        WHERE t.wikidata_id = NULLIF(d.wikidata_id, '')
          AND NULLIF(d.parent_wikidata_id, '') IS NOT NULL
          AND t.parent_id IS DISTINCT FROM p.id
        """
    )
    cur.execute(f"DROP TABLE {STAGE_TABLE}")
    cur.execute(
        f"""
        INSERT INTO {IMPORT_STATE_TABLE} (
            import_key,
            source_sha256,
            format_version,
            loaded_at
        )
        VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
        ON CONFLICT (import_key) DO UPDATE
        SET source_sha256 = EXCLUDED.source_sha256,
            format_version = EXCLUDED.format_version,
            loaded_at = EXCLUDED.loaded_at
        """,
        (IMPORT_KEY, source_sha256, format_version),
    )


def main() -> None:
    args = parse_args()

    source = args.source.resolve()

    if not source.is_file():
        print(f"Skipping territory import; source SQL not found: {source}")
        return

    try:
        import psycopg
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "Missing Python dependency 'psycopg'. Install requirements.txt first."
        ) from exc

    source_sha256 = compute_sha256(source)

    with psycopg.connect(
        host=args.host,
        port=args.port,
        dbname=args.dbname,
        user=args.user,
        password=args.password,
    ) as conn:
        with conn.cursor() as cur:
            ensure_import_state_table(cur)

            if not territory_table_exists(cur):
                raise RuntimeError(
                    "territory table not found. Run Liquibase schema/reference "
                    "migrations first."
                )

            if import_is_current(cur, source_sha256, args.format_version):
                print("Territory SQL import already up to date.")
                return

            print("Preparing staging table for territory SQL import...")
            recreate_stage_table(cur)

            print("Streaming territory data from SQL source into PostgreSQL...")
            load_stage_table(cur, source)

            print("Merging staged territory data...")
            merge_stage_into_territory(cur, source_sha256, args.format_version)

    print("Territory SQL import completed.")


if __name__ == "__main__":
    main()

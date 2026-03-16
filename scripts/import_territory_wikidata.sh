#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LIQUIBASE_DB_HOST="${LIQUIBASE_DB_HOST:-localhost}"
LIQUIBASE_DB_PORT="${LIQUIBASE_DB_PORT:-55432}"
LIQUIBASE_DB_NAME="${LIQUIBASE_DB_NAME:-geo2}"
LIQUIBASE_DB_USER="${LIQUIBASE_DB_USER:-geo}"
LIQUIBASE_DB_PASSWORD="${LIQUIBASE_DB_PASSWORD:-geo}"
LIQUIBASE_TERRITORY_IMPORT_FORMAT_VERSION="${LIQUIBASE_TERRITORY_IMPORT_FORMAT_VERSION:-1}"
SKIP_ADMIN_TERRITORY_SYNC="${SKIP_ADMIN_TERRITORY_SYNC:-0}"

SOURCE_SQL="${LIQUIBASE_TERRITORY_SOURCE_SQL:-$ROOT_DIR/liquibase/changelog/18-load-territory-from-wikidata.sql}"
STREAM_SCRIPT="${LIQUIBASE_TERRITORY_STREAM_SCRIPT:-$SCRIPT_DIR/stream_territory_wikidata_sql.py}"
ADMIN_SYNC_SCRIPT="${LIQUIBASE_ADMIN_SYNC_SCRIPT:-$SCRIPT_DIR/sync_admin_territory.sh}"
IMPORT_STATE_TABLE="bulk_import_state"
IMPORT_KEY="territory_wikidata"
STAGE_TABLE="territory_wikidata_stage"

usage() {
  echo "Usage: $0"
}

sql_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

require_command psql
require_command sha256sum
require_command python3

if [[ ! -f "$SOURCE_SQL" ]]; then
  echo "Skipping territory import; source SQL not found: $SOURCE_SQL"
  exit 0
fi

if [[ ! -f "$STREAM_SCRIPT" ]]; then
  echo "Missing territory stream script: $STREAM_SCRIPT" >&2
  exit 1
fi

SOURCE_SHA256="$(sha256sum "$SOURCE_SQL" | awk '{print $1}')"
IMPORT_FORMAT_VERSION="$LIQUIBASE_TERRITORY_IMPORT_FORMAT_VERSION"
IMPORT_KEY_SQL="$(sql_literal "$IMPORT_KEY")"
SOURCE_SHA256_SQL="$(sql_literal "$SOURCE_SHA256")"

export PGPASSWORD="$LIQUIBASE_DB_PASSWORD"
export PGCLIENTENCODING="${PGCLIENTENCODING:-UTF8}"
export PYTHONIOENCODING="${PYTHONIOENCODING:-UTF-8}"

PSQL=(
  psql
  -X
  -v
  ON_ERROR_STOP=1
  -h
  "$LIQUIBASE_DB_HOST"
  -p
  "$LIQUIBASE_DB_PORT"
  -U
  "$LIQUIBASE_DB_USER"
  -d
  "$LIQUIBASE_DB_NAME"
)

if [[ ! "$IMPORT_FORMAT_VERSION" =~ ^[0-9]+$ ]]; then
  echo "Invalid LIQUIBASE_TERRITORY_IMPORT_FORMAT_VERSION: $IMPORT_FORMAT_VERSION" >&2
  exit 1
fi

"${PSQL[@]}" -q <<SQL
CREATE TABLE IF NOT EXISTS ${IMPORT_STATE_TABLE} (
    import_key TEXT PRIMARY KEY,
    source_sha256 TEXT NOT NULL,
    format_version INTEGER NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SQL

if [[ "$("${PSQL[@]}" -qtAX -c "SELECT to_regclass('public.territory') IS NOT NULL")" != "t" ]]; then
  echo "territory table not found. Run Liquibase migrations first." >&2
  exit 1
fi

CURRENT_STATE="$("${PSQL[@]}" -qtAX -c "SELECT source_sha256 || '|' || format_version || '|' || CASE WHEN EXISTS (SELECT 1 FROM territory LIMIT 1) THEN '1' ELSE '0' END FROM ${IMPORT_STATE_TABLE} WHERE import_key = '${IMPORT_KEY_SQL}'")"
IMPORT_NEEDED=1
if [[ "$CURRENT_STATE" == "${SOURCE_SHA256}|${IMPORT_FORMAT_VERSION}|1" ]]; then
  echo "Territory SQL import already up to date."
  IMPORT_NEEDED=0
fi

TMP_PSQL="$(mktemp)"
trap 'rm -f "$TMP_PSQL"' EXIT

if [[ "$IMPORT_NEEDED" == "1" ]]; then
  echo "Preparing staging table for territory SQL import..."
  "${PSQL[@]}" -q <<SQL
DROP TABLE IF EXISTS ${STAGE_TABLE};
CREATE UNLOGGED TABLE ${STAGE_TABLE} (
    wikidata_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    country_iso TEXT NOT NULL,
    parent_wikidata_id TEXT,
    telephone_country_code TEXT,
    local_dialing_code TEXT,
    latitude TEXT,
    longitude TEXT
);
SQL

  echo "Streaming territory data from SQL source into PostgreSQL COPY..."
  python3 "$STREAM_SCRIPT" --source "$SOURCE_SQL" | "${PSQL[@]}" -q -c "COPY ${STAGE_TABLE} (wikidata_id, name, type, country_iso, parent_wikidata_id, telephone_country_code, local_dialing_code, latitude, longitude) FROM STDIN WITH (FORMAT csv, HEADER true)"

  {
  echo "\\set ON_ERROR_STOP on"
  echo "BEGIN;"
  echo "SET client_min_messages = warning;"
  echo "SET statement_timeout = 0;"
  printf "ANALYZE %s;\n" "$STAGE_TABLE"
  printf "INSERT INTO territory (wikidata_id, name, type, country_id, parent_id, telephone_country_code, local_dialing_code, latitude, longitude)\n"
  printf "SELECT\n"
  printf "    NULLIF(d.wikidata_id, ''),\n"
  printf "    NULLIF(d.name, ''),\n"
  printf "    NULLIF(d.type, ''),\n"
  printf "    c.id,\n"
  printf "    NULL,\n"
  printf "    NULLIF(d.telephone_country_code, ''),\n"
  printf "    NULLIF(d.local_dialing_code, ''),\n"
  printf "    CASE\n"
  printf "        WHEN NULLIF(d.latitude, '') IS NULL THEN NULL\n"
  printf "        ELSE CAST(d.latitude AS NUMERIC(9,6))\n"
  printf "    END,\n"
  printf "    CASE\n"
  printf "        WHEN NULLIF(d.longitude, '') IS NULL THEN NULL\n"
  printf "        ELSE CAST(d.longitude AS NUMERIC(9,6))\n"
  printf "    END\n"
  printf "FROM %s d\n" "$STAGE_TABLE"
  printf "JOIN country c ON c.iso_code = NULLIF(d.country_iso, '')\n"
  printf "ON CONFLICT (wikidata_id) DO UPDATE\n"
  printf "SET\n"
  printf "    name = EXCLUDED.name,\n"
  printf "    type = EXCLUDED.type,\n"
  printf "    country_id = EXCLUDED.country_id,\n"
  printf "    telephone_country_code = EXCLUDED.telephone_country_code,\n"
  printf "    local_dialing_code = EXCLUDED.local_dialing_code,\n"
  printf "    latitude = EXCLUDED.latitude,\n"
  printf "    longitude = EXCLUDED.longitude;\n"
  printf "UPDATE territory t\n"
  printf "SET parent_id = p.id\n"
  printf "FROM %s d\n" "$STAGE_TABLE"
  printf "JOIN territory p ON p.wikidata_id = NULLIF(d.parent_wikidata_id, '')\n"
  printf "WHERE t.wikidata_id = NULLIF(d.wikidata_id, '')\n"
  printf "  AND NULLIF(d.parent_wikidata_id, '') IS NOT NULL\n"
  printf "  AND t.parent_id IS DISTINCT FROM p.id;\n"
  printf "DROP TABLE %s;\n" "$STAGE_TABLE"
  printf "INSERT INTO %s (import_key, source_sha256, format_version, loaded_at)\n" "$IMPORT_STATE_TABLE"
  printf "VALUES ('%s', '%s', %s, CURRENT_TIMESTAMP)\n" "$IMPORT_KEY_SQL" "$SOURCE_SHA256_SQL" "$IMPORT_FORMAT_VERSION"
  printf "ON CONFLICT (import_key) DO UPDATE\n"
  printf "SET source_sha256 = EXCLUDED.source_sha256,\n"
  printf "    format_version = EXCLUDED.format_version,\n"
  printf "    loaded_at = EXCLUDED.loaded_at;\n"
  echo "COMMIT;"
  } > "$TMP_PSQL"

  "${PSQL[@]}" -f "$TMP_PSQL"
  echo "Territory SQL import completed."
fi

if [[ "$SKIP_ADMIN_TERRITORY_SYNC" != "1" ]]; then
  if [[ -x "$ADMIN_SYNC_SCRIPT" ]]; then
    "$ADMIN_SYNC_SCRIPT"
  elif [[ -f "$ADMIN_SYNC_SCRIPT" ]]; then
    bash "$ADMIN_SYNC_SCRIPT"
  else
    echo "Skipping admin hierarchy sync; script not found: $ADMIN_SYNC_SCRIPT"
  fi
fi

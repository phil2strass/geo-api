#!/usr/bin/env bash
set -euo pipefail

PLANET_PBF="/srv/tiles/planet-latest.osm.pbf"
OUTPUT_DIR="/srv/pgdata/osm/pays"
TMP_DIR="data/pays/tmp"
POLY_DIR="data/poly"
MAX_COUNTRIES="0"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-55432}"
DB_NAME="${DB_NAME:-geo2}"
DB_USER="${DB_USER:-geo}"
DB_PASSWORD="${DB_PASSWORD:-geo}"

GEOFABRIK_INDEX_URL="https://download.geofabrik.de/index-v1-nogeom.json"

usage() {
  cat <<'USAGE'
Usage:
  ./batch_extract_country_pbf.sh [options]

Options:
  --planet-pbf <path>    Planet file path (default: planet-latest.osm.pbf)
  --output-dir <path>    Country PBF directory (default: /srv/pgdata/osm/pays)
  --tmp-dir <path>       Temporary directory (default: data/pays/tmp)
  --poly-dir <path>      Polygon directory (default: data/poly)
  --max-countries <n>    Limit number of countries read from DB (0 = no limit)
  -h, --help             Show this help

DB connection (env vars):
  DB_HOST (default: localhost)
  DB_PORT (default: 55432)
  DB_NAME (default: geo2)
  DB_USER (default: geo)
  DB_PASSWORD (default: geo)
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: $1" >&2
    exit 1
  fi
}

is_valid_pbf() {
  local path="$1"
  [[ -s "$path" ]] && osmium fileinfo "$path" >/dev/null 2>&1
}

cleanup_tmp_extract() {
  local extract_path="$1"
  rm -f "$extract_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --planet-pbf)
      PLANET_PBF="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --tmp-dir)
      TMP_DIR="$2"
      shift 2
      ;;
    --poly-dir)
      POLY_DIR="$2"
      shift 2
      ;;
    --max-countries)
      MAX_COUNTRIES="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd wget
require_cmd jq
require_cmd psql
require_cmd osmium

if [[ ! -f "$PLANET_PBF" ]]; then
  echo "[ERROR] Planet file not found: $PLANET_PBF" >&2
  exit 1
fi

if ! [[ "$MAX_COUNTRIES" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --max-countries must be an integer >= 0" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$TMP_DIR" "$POLY_DIR"

INDEX_FILE="$TMP_DIR/geofabrik-index-v1-nogeom.json"
COUNTRIES_FILE="$TMP_DIR/countries_from_db.tsv"

echo "[INFO] Downloading Geofabrik index..."
wget -q -O "$INDEX_FILE" "$GEOFABRIK_INDEX_URL"

declare -A POLY_BY_ISO2
declare -A POLY_BY_ISO3

while IFS=$'\t' read -r iso2 pbf_url; do
  [[ -n "$pbf_url" ]] || continue
  if [[ "$pbf_url" != *-latest.osm.pbf ]]; then
    continue
  fi
  poly_url="${pbf_url%-latest.osm.pbf}.poly"
  iso2="${iso2,,}"
  if [[ -n "$iso2" && -z "${POLY_BY_ISO2[$iso2]+x}" ]]; then
    POLY_BY_ISO2[$iso2]="$poly_url"
  fi
done < <(
  jq -r '
    .features[]
    | select(.properties.urls.pbf != null)
    | .properties.urls.pbf as $pbf
    | (
        .properties["iso3166-1:alpha2"]
        // .properties.iso3166_1_alpha2
        // []
      ) as $iso2
    | (if ($iso2 | type) == "array" then $iso2[] else $iso2 end)
    | select(. != null and . != "")
    | [., $pbf]
    | @tsv
  ' "$INDEX_FILE"
)

while IFS=$'\t' read -r iso3 pbf_url; do
  [[ -n "$pbf_url" ]] || continue
  if [[ "$pbf_url" != *-latest.osm.pbf ]]; then
    continue
  fi
  poly_url="${pbf_url%-latest.osm.pbf}.poly"
  iso3="${iso3,,}"
  if [[ -n "$iso3" && -z "${POLY_BY_ISO3[$iso3]+x}" ]]; then
    POLY_BY_ISO3[$iso3]="$poly_url"
  fi
done < <(
  jq -r '
    .features[]
    | select(.properties.urls.pbf != null)
    | .properties.urls.pbf as $pbf
    | (
        .properties["iso3166-1:alpha3"]
        // .properties.iso3166_1_alpha3
        // []
      ) as $iso3
    | (if ($iso3 | type) == "array" then $iso3[] else $iso3 end)
    | select(. != null and . != "")
    | [., $pbf]
    | @tsv
  ' "$INDEX_FILE"
)

SQL_QUERY=$'SELECT id::text,\n       trim(name),\n       lower(coalesce(trim(iso_code), \'\')),\n       lower(coalesce(trim(iso3_code), \'\'))\nFROM country\nWHERE trim(coalesce(name, \'\')) <> \'\'\nORDER BY id'
if [[ "$MAX_COUNTRIES" -gt 0 ]]; then
  SQL_QUERY="${SQL_QUERY}"$'\nLIMIT '"$MAX_COUNTRIES"
fi
SQL_QUERY="${SQL_QUERY};"

echo "[INFO] Reading countries from DB..."
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -X -A -t -F $'\t' \
  -c "$SQL_QUERY" > "$COUNTRIES_FILE"

total=0
generated=0
skipped=0
failed=0

while IFS=$'\t' read -r country_id country_name iso2 iso3; do
  [[ -n "$country_id" ]] || continue
  total=$((total + 1))

  poly_url=""
  if [[ -n "$iso2" && -n "${POLY_BY_ISO2[$iso2]:-}" ]]; then
    poly_url="${POLY_BY_ISO2[$iso2]}"
  elif [[ -n "$iso3" && -n "${POLY_BY_ISO3[$iso3]:-}" ]]; then
    poly_url="${POLY_BY_ISO3[$iso3]}"
  fi

  if [[ -z "$poly_url" ]]; then
    echo "[WARN] [$country_id] $country_name: no Geofabrik poly URL found (iso2=$iso2 iso3=$iso3)."
    skipped=$((skipped + 1))
    continue
  fi

  poly_path="$POLY_DIR/${country_id}.poly"
  country_extract_path="$TMP_DIR/${country_id}.osm.pbf"
  country_pbf_path="$OUTPUT_DIR/${country_id}.osm.pbf"

  if is_valid_pbf "$country_pbf_path"; then
    echo "[INFO] [$country_id] $country_name"
    echo "[INFO] [$country_id] PBF already exists, skipping: $country_pbf_path"
    generated=$((generated + 1))
    continue
  fi

  if ! (
    echo "[INFO] [$country_id] $country_name"
    echo "[INFO] [$country_id] Step 1/2: poly"
    if [[ -s "$poly_path" ]]; then
      echo "       Reusing existing: $poly_path"
    else
      echo "       Downloading: $poly_url"
      if ! wget -nv -O "$poly_path" "$poly_url"; then
        echo "[ERROR] [$country_id] Failed to download poly."
        cleanup_tmp_extract "$country_extract_path"
        rm -f "$poly_path"
        exit 1
      fi
    fi

    if is_valid_pbf "$country_extract_path"; then
      echo "[INFO] [$country_id] Step 2/2: reusing existing extract: $country_extract_path"
    else
      echo "[INFO] [$country_id] Step 2/2: osmium extract (this can be long)"
      if ! osmium extract -p "$poly_path" "$PLANET_PBF" -o "$country_extract_path" --overwrite; then
        echo "[ERROR] [$country_id] osmium extract failed."
        cleanup_tmp_extract "$country_extract_path"
        rm -f "$country_pbf_path"
        exit 1
      fi
    fi

    echo "[INFO] [$country_id] Copying final PBF -> $country_pbf_path"
    if ! cp -f "$country_extract_path" "$country_pbf_path"; then
      echo "[ERROR] [$country_id] copy to final directory failed."
      cleanup_tmp_extract "$country_extract_path"
      rm -f "$country_pbf_path"
      exit 1
    fi

    cleanup_tmp_extract "$country_extract_path"
    echo "[INFO] [$country_id] Done."
  ); then
    failed=$((failed + 1))
    cleanup_tmp_extract "$country_extract_path"
    rm -f "$country_pbf_path"
    echo "[WARN] [$country_id] Failed, continuing with next country."
    continue
  fi

  generated=$((generated + 1))
done < "$COUNTRIES_FILE"

echo "[INFO] Done."
echo "[INFO] Total countries read: $total"
echo "[INFO] Generated files:      $generated"
echo "[INFO] Skipped countries:    $skipped"
echo "[INFO] Failed countries:     $failed"
echo "[INFO] Country PBF dir:      $OUTPUT_DIR"

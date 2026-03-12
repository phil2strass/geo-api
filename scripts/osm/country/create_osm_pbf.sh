#!/usr/bin/env bash
set -uo pipefail

WORLD_DEM_VRT="data/world_30m.vrt"
COUNTRY_PBF_DIR="/srv/pgdata/osm/pays"
OUTPUT_DIR="/srv/pgdata/osm/dem/tif"
TMP_DIR="data/relief/tmp"
COUNTRIES_SHP="data/countries/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp"
COUNTRIES_LAYER="ne_10m_admin_0_countries"
MAX_COUNTRIES="0"
SKIP_EXISTING="0"
MAINLAND_MODE="1"
COUNTRY_ID=""
MAINLAND_BUFFER_DEG="2.0"

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-55432}"
DB_NAME="${DB_NAME:-geo2}"
DB_USER="${DB_USER:-geo}"
DB_PASSWORD="${DB_PASSWORD:-geo}"

usage() {
  cat <<'USAGE'
Usage:
  ./batch/countries_dem.sh [options]

Options:
  --world-dem <path>         World DEM VRT/TIF input (default: world_30m.vrt)
  --country-pbf-dir <path>   Country PBF directory (default: /srv/pgdata/osm/pays)
  --output-dir <path>        Output DEM directory (default: /srv/pgdata/osm/dem)
  --tmp-dir <path>           Temporary directory (default: data/relief/tmp)
  --countries-shp <path>     Natural Earth countries shapefile path
                             (default: data/countries/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp)
  --max-countries <n>        Limit number of countries processed (0 = no limit)
  --country-id <id>          Process only one country id (expects <country-pbf-dir>/<id>.osm.pbf)
  --mainland-buffer-deg <n>  In mainland mode, include nearby polygons around largest one
                             (degrees, default: 2.0)
  --skip-existing            Skip country if /output/id.tif already exists
  --full-extent              Disable mainland mode, use full PBF bbox
  -h, --help                 Show this help

Behavior:
  - Reads each id_pays from <country-pbf-dir>/id_pays.osm.pbf
  - Default mode (mainland): tries to compute mainland bbox from Natural Earth
    using country.iso_code / country.iso3_code (largest polygon only, i.e. "metropole-like")
  - Fallback mode: if mainland bbox is unavailable, uses `osmium fileinfo -g data.bbox`
  - Clips <world-dem> into <output-dir>/id_pays.tif with gdal_translate -projwin
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: $1" >&2
    exit 1
  fi
}

is_number() {
  local value="$1"
  [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

to_human_bytes() {
  local bytes="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$bytes"
  else
    echo "${bytes}B"
  fi
}

sql_escape_literal() {
  local value="$1"
  printf "%s" "${value//\'/\'\'}"
}

validate_bbox() {
  local min_lon="$1"
  local min_lat="$2"
  local max_lon="$3"
  local max_lat="$4"

  if ! is_number "$min_lon" || ! is_number "$min_lat" || ! is_number "$max_lon" || ! is_number "$max_lat"; then
    return 1
  fi

  awk -v minx="$min_lon" -v miny="$min_lat" -v maxx="$max_lon" -v maxy="$max_lat" \
    'BEGIN { exit !(minx < maxx && miny < maxy) }'
}

get_pbf_bbox() {
  local country_file="$1"
  local bbox

  # Fast path: header bbox when available.
  bbox="$(osmium fileinfo -g data.bbox "$country_file" 2>/dev/null || true)"
  if [[ -z "$bbox" ]]; then
    # Slow path: compute bbox by scanning entities.
    bbox="$(osmium fileinfo -e -g data.bbox "$country_file" 2>/dev/null || true)"
  fi

  # Normalize formats like "(minx,miny,maxx,maxy)".
  bbox="${bbox//[[:space:]]/}"
  bbox="${bbox#(}"
  bbox="${bbox%)}"

  printf "%s" "$bbox"
}

get_mainland_bbox_from_ne() {
  local country_id="$1"
  local country_name="$2"
  local iso2="$3"
  local iso3="$4"
  local tmp_gpkg
  local where_clause
  local feature_count
  local bbox_line
  local escaped_name
  local -a where_clauses=()

  [[ -n "$iso3" ]] && where_clauses+=(
    "ADM0_A3='${iso3}'"
    "ISO_A3='${iso3}'"
    "ISO_A3_EH='${iso3}'"
  )
  [[ -n "$iso2" ]] && where_clauses+=(
    "ISO_A2='${iso2}'"
    "ISO_A2_EH='${iso2}'"
  )
  if [[ -n "$country_name" ]]; then
    escaped_name="$(sql_escape_literal "$country_name")"
    where_clauses+=("ADMIN='${escaped_name}'")
  fi

  for where_clause in "${where_clauses[@]}"; do
    tmp_gpkg="$(mktemp -u "$TMP_DIR/mainland_${country_id}_XXXXXX.gpkg")"
    rm -f "$tmp_gpkg"

    if ! ogr2ogr \
      -f GPKG \
      "$tmp_gpkg" \
      "$COUNTRIES_SHP" \
      -dialect sqlite \
      -sql "SELECT * FROM ${COUNTRIES_LAYER} WHERE ${where_clause}" \
      -explodecollections \
      -nln parts \
      -overwrite >/dev/null 2>&1; then
      rm -f "$tmp_gpkg"
      continue
    fi

    feature_count="$(ogrinfo -ro -so "$tmp_gpkg" parts 2>/dev/null | awk -F': ' '/Feature Count/ {print $2; exit}')"
    if ! [[ "$feature_count" =~ ^[0-9]+$ ]] || [[ "$feature_count" -eq 0 ]]; then
      rm -f "$tmp_gpkg"
      continue
    fi

    bbox_line="$(
      ogrinfo -ro "$tmp_gpkg" -dialect sqlite -sql \
        "SELECT
           MIN(ST_MinX(p.GEOMETRY)) AS minx,
           MIN(ST_MinY(p.GEOMETRY)) AS miny,
           MAX(ST_MaxX(p.GEOMETRY)) AS maxx,
           MAX(ST_MaxY(p.GEOMETRY)) AS maxy
         FROM parts p,
              (SELECT GEOMETRY AS geom FROM parts ORDER BY ST_Area(GEOMETRY) DESC LIMIT 1) l
         WHERE ST_Intersects(p.GEOMETRY, ST_Buffer(l.geom, $MAINLAND_BUFFER_DEG))" \
        2>/dev/null | awk -F'= ' '
          /minx \(Real\)/ {minx=$2}
          /miny \(Real\)/ {miny=$2}
          /maxx \(Real\)/ {maxx=$2}
          /maxy \(Real\)/ {maxy=$2}
          END {
            if (minx != "" && miny != "" && maxx != "" && maxy != "") {
              printf "%s,%s,%s,%s", minx, miny, maxx, maxy
            }
          }
        '
    )"
    if [[ -z "$bbox_line" ]]; then
      # Fallback to largest polygon only if cluster query fails.
      bbox_line="$(
        ogrinfo -ro "$tmp_gpkg" -dialect sqlite -sql \
          "SELECT ST_MinX(GEOMETRY) AS minx, ST_MinY(GEOMETRY) AS miny, ST_MaxX(GEOMETRY) AS maxx, ST_MaxY(GEOMETRY) AS maxy FROM (SELECT GEOMETRY FROM parts ORDER BY ST_Area(GEOMETRY) DESC LIMIT 1)" \
          2>/dev/null | awk -F'= ' '
            /minx \(Real\)/ {minx=$2}
            /miny \(Real\)/ {miny=$2}
            /maxx \(Real\)/ {maxx=$2}
            /maxy \(Real\)/ {maxy=$2}
            END {
              if (minx != "" && miny != "" && maxx != "" && maxy != "") {
                printf "%s,%s,%s,%s", minx, miny, maxx, maxy
              }
            }
          '
      )"
    fi
    rm -f "$tmp_gpkg"

    if [[ -n "$bbox_line" ]]; then
      printf "%s" "$bbox_line"
      return 0
    fi
  done

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --world-dem)
      WORLD_DEM_VRT="$2"
      shift 2
      ;;
    --country-pbf-dir)
      COUNTRY_PBF_DIR="$2"
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
    --countries-shp)
      COUNTRIES_SHP="$2"
      shift 2
      ;;
    --max-countries)
      MAX_COUNTRIES="$2"
      shift 2
      ;;
    --country-id)
      COUNTRY_ID="$2"
      shift 2
      ;;
    --mainland-buffer-deg)
      MAINLAND_BUFFER_DEG="$2"
      shift 2
      ;;
    --skip-existing)
      SKIP_EXISTING="1"
      shift
      ;;
    --full-extent)
      MAINLAND_MODE="0"
      shift
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

require_cmd osmium
require_cmd gdal_translate
require_cmd gdalinfo
require_cmd awk
require_cmd find

if [[ "$MAINLAND_MODE" == "1" ]]; then
  require_cmd ogr2ogr
  require_cmd ogrinfo
fi

if ! [[ "$MAX_COUNTRIES" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --max-countries must be an integer >= 0" >&2
  exit 1
fi

if [[ -n "$COUNTRY_ID" ]] && ! [[ "$COUNTRY_ID" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --country-id must be a numeric id" >&2
  exit 1
fi

if ! is_number "$MAINLAND_BUFFER_DEG"; then
  echo "[ERROR] --mainland-buffer-deg must be numeric" >&2
  exit 1
fi
if awk -v v="$MAINLAND_BUFFER_DEG" 'BEGIN { exit !(v < 0) }'; then
  echo "[ERROR] --mainland-buffer-deg must be >= 0" >&2
  exit 1
fi

if [[ ! -f "$WORLD_DEM_VRT" ]]; then
  echo "[ERROR] World DEM not found: $WORLD_DEM_VRT" >&2
  exit 1
fi

if [[ ! -d "$COUNTRY_PBF_DIR" ]]; then
  echo "[ERROR] Country PBF directory not found: $COUNTRY_PBF_DIR" >&2
  exit 1
fi

if [[ "$MAINLAND_MODE" == "1" && ! -f "$COUNTRIES_SHP" ]]; then
  echo "[ERROR] Countries shapefile not found: $COUNTRIES_SHP" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$TMP_DIR"

shopt -s nullglob
country_files=( "$COUNTRY_PBF_DIR"/*.osm.pbf )
shopt -u nullglob

if [[ -n "$COUNTRY_ID" ]]; then
  single_country_file="$COUNTRY_PBF_DIR/${COUNTRY_ID}.osm.pbf"
  if [[ ! -f "$single_country_file" ]]; then
    echo "[ERROR] Country PBF not found for --country-id=$COUNTRY_ID: $single_country_file" >&2
    exit 1
  fi
  country_files=( "$single_country_file" )
fi

if [[ ${#country_files[@]} -eq 0 ]]; then
  echo "[ERROR] No country PBF found in: $COUNTRY_PBF_DIR" >&2
  exit 1
fi

declare -A NAME_BY_ID=()
declare -A ISO2_BY_ID=()
declare -A ISO3_BY_ID=()
HAS_COUNTRY_MAP="0"

if [[ "$MAINLAND_MODE" == "1" ]] && command -v psql >/dev/null 2>&1; then
  map_file="$TMP_DIR/countries_from_db.tsv"
  SQL_QUERY=$'SELECT id::text,\n       trim(name),\n       upper(coalesce(trim(iso_code), \'\')),\n       upper(coalesce(trim(iso3_code), \'\'))\nFROM country\nWHERE trim(coalesce(name, \'\')) <> \'\'\nORDER BY id;'

  if PGPASSWORD="$DB_PASSWORD" psql \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -X -A -t -F $'\t' \
    -c "$SQL_QUERY" > "$map_file" 2>/dev/null; then
    while IFS=$'\t' read -r cid cname ciso2 ciso3; do
      [[ -n "$cid" ]] || continue
      NAME_BY_ID["$cid"]="$cname"
      ISO2_BY_ID["$cid"]="$ciso2"
      ISO3_BY_ID["$cid"]="$ciso3"
    done < "$map_file"
    HAS_COUNTRY_MAP="1"
  else
    echo "[WARN] DB country map unavailable. Mainland mode may fallback to PBF bbox."
  fi
elif [[ "$MAINLAND_MODE" == "1" ]]; then
  echo "[WARN] psql not found. Mainland mode may fallback to PBF bbox."
fi

echo "[INFO] Input DEM:         $WORLD_DEM_VRT"
echo "[INFO] Country PBF dir:   $COUNTRY_PBF_DIR"
echo "[INFO] Output DEM dir:    $OUTPUT_DIR"
echo "[INFO] Mainland mode:     $MAINLAND_MODE"
echo "[INFO] Country id filter: ${COUNTRY_ID:-none}"
if [[ "$MAINLAND_MODE" == "1" ]]; then
  echo "[INFO] Countries shapefile:$COUNTRIES_SHP"
  echo "[INFO] Country map loaded: $HAS_COUNTRY_MAP"
  echo "[INFO] Mainland buffer deg:$MAINLAND_BUFFER_DEG"
fi

total=0
processed=0
skipped=0
failed=0
created_bytes=0
declare -a failed_countries=()

for country_file in "${country_files[@]}"; do
  if [[ "$MAX_COUNTRIES" -gt 0 && "$total" -ge "$MAX_COUNTRIES" ]]; then
    break
  fi

  country_id="$(basename "$country_file" ".osm.pbf")"
  output_tif="$OUTPUT_DIR/${country_id}.tif"
  total=$((total + 1))

  if [[ "$SKIP_EXISTING" == "1" && -s "$output_tif" ]]; then
    echo "[INFO] [$country_id] DEM already exists, skipping."
    skipped=$((skipped + 1))
    continue
  fi

  bbox=""
  bbox_source=""
  country_name="${NAME_BY_ID[$country_id]:-}"
  iso2="${ISO2_BY_ID[$country_id]:-}"
  iso3="${ISO3_BY_ID[$country_id]:-}"

  if [[ "$MAINLAND_MODE" == "1" ]]; then
    bbox="$(get_mainland_bbox_from_ne "$country_id" "$country_name" "$iso2" "$iso3" || true)"
    if [[ -n "$bbox" ]]; then
      bbox_source="mainland"
    fi
  fi

  if [[ -z "$bbox" ]]; then
    bbox="$(get_pbf_bbox "$country_file")"
    bbox_source="pbf"
  fi

  if [[ -z "$bbox" ]]; then
    echo "[ERROR] [$country_id] Unable to compute bbox."
    failed=$((failed + 1))
    failed_countries+=("$country_id")
    continue
  fi

  IFS=',' read -r min_lon min_lat max_lon max_lat <<< "$bbox"
  if ! validate_bbox "$min_lon" "$min_lat" "$max_lon" "$max_lat"; then
    echo "[ERROR] [$country_id] Invalid bbox values: $bbox"
    failed=$((failed + 1))
    failed_countries+=("$country_id")
    continue
  fi

  echo "[INFO] [$country_id] bbox_source=$bbox_source bbox=$bbox"
  rm -f "$output_tif"
  if ! gdal_translate \
    -projwin "$min_lon" "$max_lat" "$max_lon" "$min_lat" \
    -co TILED=YES \
    -co COMPRESS=DEFLATE \
    -co PREDICTOR=2 \
    -co BIGTIFF=IF_SAFER \
    "$WORLD_DEM_VRT" \
    "$output_tif"; then
    echo "[ERROR] [$country_id] gdal_translate failed."
    rm -f "$output_tif"
    failed=$((failed + 1))
    failed_countries+=("$country_id")
    continue
  fi

  if [[ ! -s "$output_tif" ]]; then
    echo "[ERROR] [$country_id] Output DEM is empty."
    rm -f "$output_tif"
    failed=$((failed + 1))
    failed_countries+=("$country_id")
    continue
  fi

  file_size="$(stat -c '%s' "$output_tif" 2>/dev/null || echo 0)"
  created_bytes=$((created_bytes + file_size))
  processed=$((processed + 1))
  echo "[INFO] [$country_id] Done -> $output_tif ($(to_human_bytes "$file_size"))"
done

total_dir_bytes="$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '*.tif' -printf '%s\n' 2>/dev/null | awk 'BEGIN {s=0} {s+=$1} END {printf "%.0f", s}')"

echo "[INFO] Batch finished."
echo "[INFO] Countries seen:        $total"
echo "[INFO] Processed:             $processed"
echo "[INFO] Skipped existing:      $skipped"
echo "[INFO] Failed:                $failed"
echo "[INFO] Size created this run: $created_bytes bytes ($(to_human_bytes "$created_bytes"))"
echo "[INFO] Total output size:     $total_dir_bytes bytes ($(to_human_bytes "$total_dir_bytes"))"

if [[ ${#failed_countries[@]} -gt 0 ]]; then
  echo "[INFO] Countries not processed:"
  for country_id in "${failed_countries[@]}"; do
    echo " - $country_id"
  done
else
  echo "[INFO] Countries not processed: none"
fi

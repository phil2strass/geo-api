#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LIQUIBASE_DB_HOST="${LIQUIBASE_DB_HOST:-localhost}"
LIQUIBASE_DB_PORT="${LIQUIBASE_DB_PORT:-55432}"
LIQUIBASE_DB_NAME="${LIQUIBASE_DB_NAME:-geo2}"
LIQUIBASE_DB_USER="${LIQUIBASE_DB_USER:-geo}"
LIQUIBASE_DB_PASSWORD="${LIQUIBASE_DB_PASSWORD:-geo}"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

require_command psql

export PGPASSWORD="$LIQUIBASE_DB_PASSWORD"
export PGCLIENTENCODING="${PGCLIENTENCODING:-UTF8}"
FR_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/fr_admin_seed.tsv"
DE_KREISE_SEED_PATH="${SCRIPT_DIR}/data/de_kreise_seed.tsv"
DE_MUNICIPALITY_SEED_PATH="${SCRIPT_DIR}/data/de_municipality_seed.tsv"
GB_LAD_SEED_PATH="${SCRIPT_DIR}/data/gb_local_authority_district_seed.tsv"
GB_WARD_SEED_PATH="${SCRIPT_DIR}/data/gb_electoral_ward_division_seed.tsv"
BE_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/be_admin_seed.tsv"
LU_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/lu_admin_seed.tsv"
NL_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/nl_admin_seed.tsv"
DK_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/dk_admin_seed.tsv"
CH_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/ch_admin_seed.tsv"
AT_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/at_admin_seed.tsv"
IT_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/it_admin_seed.tsv"
IE_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/ie_admin_seed.tsv"
ES_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/es_admin_seed.tsv"
PT_ADMIN_SEED_PATH="${SCRIPT_DIR}/data/pt_admin_seed.tsv"

if [[ ! -f "$FR_ADMIN_SEED_PATH" ]]; then
  echo "Missing France admin seed file: $FR_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$DE_KREISE_SEED_PATH" ]]; then
  echo "Missing Germany Kreis seed file: $DE_KREISE_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$DE_MUNICIPALITY_SEED_PATH" ]]; then
  echo "Missing Germany municipality seed file: $DE_MUNICIPALITY_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$GB_LAD_SEED_PATH" ]]; then
  echo "Missing United Kingdom local authority seed file: $GB_LAD_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$GB_WARD_SEED_PATH" ]]; then
  echo "Missing United Kingdom electoral ward/division seed file: $GB_WARD_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$BE_ADMIN_SEED_PATH" ]]; then
  echo "Missing Belgium admin seed file: $BE_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$LU_ADMIN_SEED_PATH" ]]; then
  echo "Missing Luxembourg admin seed file: $LU_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$NL_ADMIN_SEED_PATH" ]]; then
  echo "Missing Netherlands admin seed file: $NL_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$DK_ADMIN_SEED_PATH" ]]; then
  echo "Missing Denmark admin seed file: $DK_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$CH_ADMIN_SEED_PATH" ]]; then
  echo "Missing Switzerland admin seed file: $CH_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$AT_ADMIN_SEED_PATH" ]]; then
  echo "Missing Austria admin seed file: $AT_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$IT_ADMIN_SEED_PATH" ]]; then
  echo "Missing Italy admin seed file: $IT_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$IE_ADMIN_SEED_PATH" ]]; then
  echo "Missing Ireland admin seed file: $IE_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$ES_ADMIN_SEED_PATH" ]]; then
  echo "Missing Spain admin seed file: $ES_ADMIN_SEED_PATH" >&2
  exit 1
fi

if [[ ! -f "$PT_ADMIN_SEED_PATH" ]]; then
  echo "Missing Portugal admin seed file: $PT_ADMIN_SEED_PATH" >&2
  exit 1
fi

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

if [[ "$("${PSQL[@]}" -qtAX -c "SELECT to_regclass('public.country_admin_level') IS NOT NULL AND to_regclass('public.admin_territory') IS NOT NULL")" != "t" ]]; then
  echo "Skipping admin hierarchy sync; country_admin_level/admin_territory tables not found."
  exit 0
fi

if [[ "$("${PSQL[@]}" -qtAX -c "SELECT to_regclass('public.territory') IS NOT NULL")" != "t" ]]; then
  echo "Skipping admin hierarchy sync; territory table not found."
  exit 0
fi

echo "Synchronizing administrative hierarchy for France, Germany, the United Kingdom, Ireland, Spain, Portugal, Belgium, Luxembourg, Switzerland, Austria, Denmark, the Netherlands and Italy..."
{
cat <<'SQL'
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE de_kreise_seed (
    admin_code VARCHAR(5) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_state_code VARCHAR(2) NOT NULL,
    parent_government_region_code VARCHAR(3),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE de_municipality_seed (
    admin_code VARCHAR(8) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_kreis_code VARCHAR(5) NOT NULL,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE fr_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) NOT NULL,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL,
    PRIMARY KEY (level_code, admin_code)
) ON COMMIT DROP;

CREATE TEMP TABLE gb_lad_seed (
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_country_code VARCHAR(9) NOT NULL,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE gb_ward_seed (
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32),
    parent_lad_code VARCHAR(9) NOT NULL,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE be_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE lu_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE nl_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    territory_type VARCHAR(32) NOT NULL,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE dk_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE ch_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE at_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL,
    territory_type VARCHAR(32) NOT NULL,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE it_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL,
    territory_type VARCHAR(32) NOT NULL,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE ie_admin_seed (
    admin_code VARCHAR(9) PRIMARY KEY,
    display_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL UNIQUE,
    source VARCHAR(120) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE es_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) NOT NULL,
    display_name TEXT NOT NULL,
    territory_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL,
    territory_type VARCHAR(32) NOT NULL,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL,
    PRIMARY KEY (level_code, admin_code)
) ON COMMIT DROP;

CREATE TEMP TABLE pt_admin_seed (
    level_code VARCHAR(64) NOT NULL,
    admin_code VARCHAR(9) NOT NULL,
    display_name TEXT NOT NULL,
    territory_name TEXT NOT NULL,
    territory_wikidata_id VARCHAR(32) NOT NULL,
    territory_type VARCHAR(32) NOT NULL,
    parent_level_code VARCHAR(64),
    parent_admin_code VARCHAR(9),
    source VARCHAR(120) NOT NULL,
    PRIMARY KEY (level_code, admin_code)
) ON COMMIT DROP;
SQL

printf "\\copy de_kreise_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$DE_KREISE_SEED_PATH"
printf "\\copy de_municipality_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$DE_MUNICIPALITY_SEED_PATH"
printf "\\copy fr_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$FR_ADMIN_SEED_PATH"
printf "\\copy gb_lad_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$GB_LAD_SEED_PATH"
printf "\\copy gb_ward_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$GB_WARD_SEED_PATH"
printf "\\copy be_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$BE_ADMIN_SEED_PATH"
printf "\\copy lu_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$LU_ADMIN_SEED_PATH"
printf "\\copy nl_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$NL_ADMIN_SEED_PATH"
printf "\\copy dk_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$DK_ADMIN_SEED_PATH"
printf "\\copy ch_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$CH_ADMIN_SEED_PATH"
printf "\\copy at_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$AT_ADMIN_SEED_PATH"
printf "\\copy it_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$IT_ADMIN_SEED_PATH"
printf "\\copy ie_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$IE_ADMIN_SEED_PATH"
printf "\\copy es_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$ES_ADMIN_SEED_PATH"
printf "\\copy pt_admin_seed FROM '%s' WITH (FORMAT csv, DELIMITER E'\\\\t', HEADER true)\n" "$PT_ADMIN_SEED_PATH"

cat <<'SQL'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM fr_admin_seed) THEN
        RAISE EXCEPTION 'France admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM de_kreise_seed) THEN
        RAISE EXCEPTION 'Germany Kreis seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM de_municipality_seed) THEN
        RAISE EXCEPTION 'Germany municipality seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gb_lad_seed) THEN
        RAISE EXCEPTION 'United Kingdom local authority seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM gb_ward_seed) THEN
        RAISE EXCEPTION 'United Kingdom electoral ward/division seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM be_admin_seed) THEN
        RAISE EXCEPTION 'Belgium admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM lu_admin_seed) THEN
        RAISE EXCEPTION 'Luxembourg admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM nl_admin_seed) THEN
        RAISE EXCEPTION 'Netherlands admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dk_admin_seed) THEN
        RAISE EXCEPTION 'Denmark admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ch_admin_seed) THEN
        RAISE EXCEPTION 'Switzerland admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM at_admin_seed) THEN
        RAISE EXCEPTION 'Austria admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM it_admin_seed) THEN
        RAISE EXCEPTION 'Italy admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ie_admin_seed) THEN
        RAISE EXCEPTION 'Ireland admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM es_admin_seed) THEN
        RAISE EXCEPTION 'Spain admin seed is empty';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pt_admin_seed) THEN
        RAISE EXCEPTION 'Portugal admin seed is empty';
    END IF;
END $$;

WITH france AS (
    SELECT id
    FROM country
    WHERE iso_code = 'FR'
)
DELETE FROM admin_territory
USING france
WHERE admin_territory.country_id = france.id;

WITH france AS (
    SELECT id
    FROM country
    WHERE iso_code = 'FR'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM france)
),
region_seed(admin_code, display_name, territory_wikidata_id, source) AS (
    VALUES
        ('01', 'Guadeloupe', 'Q17012', 'seed.fr_admin_region'),
        ('02', 'Martinique', 'Q17054', 'seed.fr_admin_region'),
        ('03', 'Guyane', 'Q3769', 'seed.fr_admin_region'),
        ('04', 'La Réunion', 'Q17070', 'seed.fr_admin_region'),
        ('06', 'Mayotte', 'Q17063', 'seed.fr_admin_region'),
        ('11', 'Île-de-France', 'Q13917', 'seed.fr_admin_region'),
        ('24', 'Centre-Val de Loire', 'Q13947', 'seed.fr_admin_region'),
        ('27', 'Bourgogne-Franche-Comté', 'Q18578267', 'seed.fr_admin_region'),
        ('28', 'Normandie', 'Q18677875', 'seed.fr_admin_region'),
        ('32', 'Hauts-de-France', 'Q18677767', 'seed.fr_admin_region'),
        ('44', 'Grand Est', 'Q18677983', 'seed.fr_admin_region'),
        ('52', 'Pays de la Loire', 'Q16994', 'seed.fr_admin_region'),
        ('53', 'Bretagne', 'Q12130', 'seed.fr_admin_region'),
        ('75', 'Nouvelle-Aquitaine', 'Q18678082', 'seed.fr_admin_region'),
        ('76', 'Occitanie', 'Q18678265', 'seed.fr_admin_region'),
        ('84', 'Auvergne-Rhône-Alpes', 'Q18338206', 'seed.fr_admin_region'),
        ('93', 'Provence-Alpes-Côte d''Azur', 'Q15104', 'seed.fr_admin_region'),
        ('94', 'Corse', 'Q14112', 'seed.fr_admin_region')
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    rl.country_id,
    rl.id,
    t.id,
    NULL,
    rs.display_name,
    rs.admin_code,
    'fr_insee',
    TRUE,
    TRUE,
    rs.source
FROM region_level rl
JOIN france f ON f.id = rl.country_id
JOIN region_seed rs ON TRUE
JOIN territory t
    ON t.country_id = f.id
   AND t.wikidata_id = rs.territory_wikidata_id;

WITH france AS (
    SELECT id
    FROM country
    WHERE iso_code = 'FR'
),
department_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'department'
      AND country_id = (SELECT id FROM france)
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM france)
),
department_seed(admin_code, display_name, territory_wikidata_id, parent_region_code, source) AS (
    VALUES
        ('01', 'Ain', 'Q3083', '84', 'seed.fr_admin_department'),
        ('02', 'Aisne', 'Q3093', '32', 'seed.fr_admin_department'),
        ('03', 'Allier', 'Q3113', '84', 'seed.fr_admin_department'),
        ('04', 'Alpes-de-Haute-Provence', 'Q3131', '93', 'seed.fr_admin_department'),
        ('05', 'Hautes-Alpes', 'Q3125', '93', 'seed.fr_admin_department'),
        ('06', 'Alpes-Maritimes', 'Q3139', '93', 'seed.fr_admin_department'),
        ('07', 'Ardèche', 'Q3148', '84', 'seed.fr_admin_department'),
        ('08', 'Ardennes', 'Q3164', '44', 'seed.fr_admin_department'),
        ('09', 'Ariège', 'Q3184', '76', 'seed.fr_admin_department'),
        ('10', 'Aube', 'Q3194', '44', 'seed.fr_admin_department'),
        ('11', 'Aude', 'Q3207', '76', 'seed.fr_admin_department'),
        ('12', 'Aveyron', 'Q3216', '76', 'seed.fr_admin_department'),
        ('13', 'Bouches-du-Rhône', 'Q3240', '93', 'seed.fr_admin_department'),
        ('14', 'Calvados', 'Q3249', '28', 'seed.fr_admin_department'),
        ('15', 'Cantal', 'Q3259', '84', 'seed.fr_admin_department'),
        ('16', 'Charente', 'Q3266', '75', 'seed.fr_admin_department'),
        ('17', 'Charente-Maritime', 'Q3278', '75', 'seed.fr_admin_department'),
        ('18', 'Cher', 'Q3286', '24', 'seed.fr_admin_department'),
        ('19', 'Corrèze', 'Q3326', '75', 'seed.fr_admin_department'),
        ('2A', 'Corse-du-Sud', 'Q3336', '94', 'seed.fr_admin_department'),
        ('2B', 'Haute-Corse', 'Q3334', '94', 'seed.fr_admin_department'),
        ('21', 'Côte-d''Or', 'Q3342', '27', 'seed.fr_admin_department'),
        ('22', 'Côtes-d''Armor', 'Q3349', '53', 'seed.fr_admin_department'),
        ('23', 'Creuse', 'Q3353', '75', 'seed.fr_admin_department'),
        ('24', 'Dordogne', 'Q3357', '75', 'seed.fr_admin_department'),
        ('25', 'Doubs', 'Q3361', '27', 'seed.fr_admin_department'),
        ('26', 'Drôme', 'Q3364', '84', 'seed.fr_admin_department'),
        ('27', 'Eure', 'Q3372', '28', 'seed.fr_admin_department'),
        ('28', 'Eure-et-Loir', 'Q3377', '24', 'seed.fr_admin_department'),
        ('29', 'Finistère', 'Q3389', '53', 'seed.fr_admin_department'),
        ('30', 'Gard', 'Q12515', '76', 'seed.fr_admin_department'),
        ('31', 'Haute-Garonne', 'Q12538', '76', 'seed.fr_admin_department'),
        ('32', 'Gers', 'Q12517', '76', 'seed.fr_admin_department'),
        ('33', 'Gironde', 'Q12526', '75', 'seed.fr_admin_department'),
        ('34', 'Hérault', 'Q12545', '76', 'seed.fr_admin_department'),
        ('35', 'Ille-et-Vilaine', 'Q12549', '53', 'seed.fr_admin_department'),
        ('36', 'Indre', 'Q12553', '24', 'seed.fr_admin_department'),
        ('37', 'Indre-et-Loire', 'Q12556', '24', 'seed.fr_admin_department'),
        ('38', 'Isère', 'Q12559', '84', 'seed.fr_admin_department'),
        ('39', 'Jura', 'Q3120', '27', 'seed.fr_admin_department'),
        ('40', 'Landes', 'Q12563', '75', 'seed.fr_admin_department'),
        ('41', 'Loir-et-Cher', 'Q12564', '24', 'seed.fr_admin_department'),
        ('42', 'Loire', 'Q12569', '84', 'seed.fr_admin_department'),
        ('43', 'Haute-Loire', 'Q12572', '84', 'seed.fr_admin_department'),
        ('44', 'Loire-Atlantique', 'Q3068', '52', 'seed.fr_admin_department'),
        ('45', 'Loiret', 'Q12574', '24', 'seed.fr_admin_department'),
        ('46', 'Lot', 'Q12576', '76', 'seed.fr_admin_department'),
        ('47', 'Lot-et-Garonne', 'Q12578', '75', 'seed.fr_admin_department'),
        ('48', 'Lozère', 'Q12580', '76', 'seed.fr_admin_department'),
        ('49', 'Maine-et-Loire', 'Q12584', '52', 'seed.fr_admin_department'),
        ('50', 'Manche', 'Q12589', '28', 'seed.fr_admin_department'),
        ('51', 'Marne', 'Q12594', '44', 'seed.fr_admin_department'),
        ('52', 'Haute-Marne', 'Q12607', '44', 'seed.fr_admin_department'),
        ('53', 'Mayenne', 'Q12620', '52', 'seed.fr_admin_department'),
        ('54', 'Meurthe-et-Moselle', 'Q12626', '44', 'seed.fr_admin_department'),
        ('55', 'Meuse', 'Q12631', '44', 'seed.fr_admin_department'),
        ('56', 'Morbihan', 'Q12642', '53', 'seed.fr_admin_department'),
        ('57', 'Moselle', 'Q12652', '44', 'seed.fr_admin_department'),
        ('58', 'Nièvre', 'Q12657', '27', 'seed.fr_admin_department'),
        ('59', 'Nord', 'Q12661', '32', 'seed.fr_admin_department'),
        ('60', 'Oise', 'Q12675', '32', 'seed.fr_admin_department'),
        ('61', 'Orne', 'Q12679', '28', 'seed.fr_admin_department'),
        ('62', 'Pas-de-Calais', 'Q12689', '32', 'seed.fr_admin_department'),
        ('63', 'Puy-de-Dôme', 'Q12694', '84', 'seed.fr_admin_department'),
        ('64', 'Pyrénées-Atlantiques', 'Q12703', '75', 'seed.fr_admin_department'),
        ('65', 'Hautes-Pyrénées', 'Q12700', '76', 'seed.fr_admin_department'),
        ('66', 'Pyrénées-Orientales', 'Q12709', '76', 'seed.fr_admin_department'),
        ('67', 'Bas-Rhin', 'Q12717', '44', 'seed.fr_admin_department'),
        ('68', 'Haut-Rhin', 'Q12722', '44', 'seed.fr_admin_department'),
        ('69', 'Rhône', 'Q46130', '84', 'seed.fr_admin_department'),
        ('70', 'Haute-Saône', 'Q12730', '27', 'seed.fr_admin_department'),
        ('71', 'Saône-et-Loire', 'Q12736', '27', 'seed.fr_admin_department'),
        ('72', 'Sarthe', 'Q12740', '52', 'seed.fr_admin_department'),
        ('73', 'Savoie', 'Q12745', '84', 'seed.fr_admin_department'),
        ('74', 'Haute-Savoie', 'Q12751', '84', 'seed.fr_admin_department'),
        ('75', 'Paris', 'Q124881945', '11', 'seed.fr_admin_department'),
        ('76', 'Seine-Maritime', 'Q12758', '28', 'seed.fr_admin_department'),
        ('77', 'Seine-et-Marne', 'Q12753', '11', 'seed.fr_admin_department'),
        ('78', 'Yvelines', 'Q12820', '11', 'seed.fr_admin_department'),
        ('79', 'Deux-Sèvres', 'Q12765', '75', 'seed.fr_admin_department'),
        ('80', 'Somme', 'Q12770', '32', 'seed.fr_admin_department'),
        ('81', 'Tarn', 'Q12772', '76', 'seed.fr_admin_department'),
        ('82', 'Tarn-et-Garonne', 'Q12779', '76', 'seed.fr_admin_department'),
        ('83', 'Var', 'Q12789', '93', 'seed.fr_admin_department'),
        ('84', 'Vaucluse', 'Q12792', '93', 'seed.fr_admin_department'),
        ('85', 'Vendée', 'Q12798', '52', 'seed.fr_admin_department'),
        ('86', 'Vienne', 'Q12804', '75', 'seed.fr_admin_department'),
        ('87', 'Haute-Vienne', 'Q12808', '75', 'seed.fr_admin_department'),
        ('88', 'Vosges', 'Q3105', '44', 'seed.fr_admin_department'),
        ('89', 'Yonne', 'Q12816', '27', 'seed.fr_admin_department'),
        ('90', 'Territoire de Belfort', 'Q12782', '27', 'seed.fr_admin_department'),
        ('91', 'Essonne', 'Q3368', '11', 'seed.fr_admin_department'),
        ('92', 'Hauts-de-Seine', 'Q12543', '11', 'seed.fr_admin_department'),
        ('93', 'Seine-Saint-Denis', 'Q12761', '11', 'seed.fr_admin_department'),
        ('94', 'Val-de-Marne', 'Q12788', '11', 'seed.fr_admin_department'),
        ('95', 'Val-d''Oise', 'Q12784', '11', 'seed.fr_admin_department'),
        ('971', 'Guadeloupe', 'Q17012', '01', 'seed.fr_admin_department'),
        ('972', 'Martinique', 'Q17054', '02', 'seed.fr_admin_department'),
        ('973', 'Guyane', 'Q3769', '03', 'seed.fr_admin_department'),
        ('974', 'La Réunion', 'Q17070', '04', 'seed.fr_admin_department'),
        ('976', 'Mayotte', 'Q17063', '06', 'seed.fr_admin_department')
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    dl.country_id,
    dl.id,
    t.id,
    parent_at.id,
    ds.display_name,
    ds.admin_code,
    'fr_insee',
    TRUE,
    TRUE,
    ds.source
FROM department_level dl
JOIN france f ON f.id = dl.country_id
JOIN department_seed ds ON TRUE
JOIN territory t
    ON t.country_id = f.id
   AND t.wikidata_id = ds.territory_wikidata_id
JOIN region_level rl ON rl.country_id = f.id
JOIN admin_territory parent_at
    ON parent_at.country_id = f.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'fr_insee'
   AND parent_at.admin_code = ds.parent_region_code;

WITH france AS (
    SELECT id
    FROM country
    WHERE iso_code = 'FR'
),
level_map AS (
    SELECT id, country_id, code
    FROM country_admin_level
    WHERE country_id = (SELECT id FROM france)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    lm.country_id,
    lm.id,
    t.id,
    parent_at.id,
    fas.display_name,
    fas.admin_code,
    'fr_insee',
    TRUE,
    TRUE,
    fas.source
FROM fr_admin_seed fas
JOIN level_map lm
    ON lm.code = fas.level_code
JOIN france f
    ON f.id = lm.country_id
JOIN territory t
    ON t.country_id = f.id
   AND t.wikidata_id = fas.territory_wikidata_id
JOIN level_map parent_level
    ON parent_level.code = fas.parent_level_code
JOIN admin_territory parent_at
    ON parent_at.country_id = f.id
   AND parent_at.admin_level_id = parent_level.id
   AND parent_at.admin_code_system = 'fr_insee'
   AND parent_at.admin_code = fas.parent_admin_code;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
)
DELETE FROM admin_territory
USING germany
WHERE admin_territory.country_id = germany.id;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
state_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state'
      AND country_id = (SELECT id FROM germany)
),
state_seed(admin_code, display_name, territory_wikidata_id, source) AS (
    VALUES
        ('08', 'Baden-Württemberg', 'Q985', 'seed.de_admin_state'),
        ('09', 'Bayern', 'Q980', 'seed.de_admin_state'),
        ('11', 'Berlin', 'Q64', 'seed.de_admin_state'),
        ('12', 'Brandenburg', 'Q1208', 'seed.de_admin_state'),
        ('04', 'Bremen', 'Q1209', 'seed.de_admin_state'),
        ('02', 'Hamburg', 'Q1055', 'seed.de_admin_state'),
        ('06', 'Hessen', 'Q1199', 'seed.de_admin_state'),
        ('03', 'Niedersachsen', 'Q1197', 'seed.de_admin_state'),
        ('13', 'Mecklenburg-Vorpommern', 'Q1196', 'seed.de_admin_state'),
        ('05', 'Nordrhein-Westfalen', 'Q1198', 'seed.de_admin_state'),
        ('07', 'Rheinland-Pfalz', 'Q1200', 'seed.de_admin_state'),
        ('10', 'Saarland', 'Q1201', 'seed.de_admin_state'),
        ('14', 'Sachsen', 'Q1202', 'seed.de_admin_state'),
        ('15', 'Sachsen-Anhalt', 'Q1206', 'seed.de_admin_state'),
        ('01', 'Schleswig-Holstein', 'Q1194', 'seed.de_admin_state'),
        ('16', 'Thüringen', 'Q1205', 'seed.de_admin_state')
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    sl.country_id,
    sl.id,
    t.id,
    NULL,
    ss.display_name,
    ss.admin_code,
    'de_ags_land',
    TRUE,
    TRUE,
    ss.source
FROM state_level sl
JOIN germany g ON g.id = sl.country_id
JOIN state_seed ss ON TRUE
JOIN territory t
    ON t.country_id = g.id
   AND t.wikidata_id = ss.territory_wikidata_id;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
state_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state'
      AND country_id = (SELECT id FROM germany)
),
government_region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'government_region'
      AND country_id = (SELECT id FROM germany)
),
government_region_seed(admin_code, display_name, territory_wikidata_id, parent_state_code, source) AS (
    VALUES
        ('081', 'Regierungsbezirk Stuttgart', 'Q8172', '08', 'seed.de_admin_government_region'),
        ('082', 'Regierungsbezirk Karlsruhe', 'Q8165', '08', 'seed.de_admin_government_region'),
        ('083', 'Regierungsbezirk Freiburg', 'Q8167', '08', 'seed.de_admin_government_region'),
        ('084', 'Regierungsbezirk Tübingen', 'Q8170', '08', 'seed.de_admin_government_region'),
        ('091', 'Oberbayern', 'Q10562', '09', 'seed.de_admin_government_region'),
        ('092', 'Niederbayern', 'Q10559', '09', 'seed.de_admin_government_region'),
        ('093', 'Oberpfalz', 'Q10555', '09', 'seed.de_admin_government_region'),
        ('094', 'Oberfranken', 'Q10554', '09', 'seed.de_admin_government_region'),
        ('095', 'Mittelfranken', 'Q10551', '09', 'seed.de_admin_government_region'),
        ('096', 'Unterfranken', 'Q10547', '09', 'seed.de_admin_government_region'),
        ('097', 'Schwaben', 'Q10557', '09', 'seed.de_admin_government_region'),
        ('064', 'Regierungsbezirk Darmstadt', 'Q7932', '06', 'seed.de_admin_government_region'),
        ('065', 'Regierungsbezirk Gießen', 'Q7931', '06', 'seed.de_admin_government_region'),
        ('066', 'Regierungsbezirk Kassel', 'Q7928', '06', 'seed.de_admin_government_region'),
        ('051', 'Regierungsbezirk Düsseldorf', 'Q7926', '05', 'seed.de_admin_government_region'),
        ('053', 'Regierungsbezirk Köln', 'Q7927', '05', 'seed.de_admin_government_region'),
        ('055', 'Regierungsbezirk Münster', 'Q7920', '05', 'seed.de_admin_government_region'),
        ('057', 'Regierungsbezirk Detmold', 'Q7923', '05', 'seed.de_admin_government_region'),
        ('059', 'Regierungsbezirk Arnsberg', 'Q7924', '05', 'seed.de_admin_government_region')
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    grl.country_id,
    grl.id,
    t.id,
    parent_at.id,
    grs.display_name,
    grs.admin_code,
    'de_ars_regierungsbezirk',
    TRUE,
    TRUE,
    grs.source
FROM government_region_level grl
JOIN germany g ON g.id = grl.country_id
JOIN government_region_seed grs ON TRUE
JOIN territory t
    ON t.country_id = g.id
   AND t.wikidata_id = grs.territory_wikidata_id
JOIN state_level sl ON sl.country_id = g.id
JOIN admin_territory parent_at
    ON parent_at.country_id = g.id
   AND parent_at.admin_level_id = sl.id
   AND parent_at.admin_code_system = 'de_ags_land'
   AND parent_at.admin_code = grs.parent_state_code;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
state_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state'
      AND country_id = (SELECT id FROM germany)
),
government_region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'government_region'
      AND country_id = (SELECT id FROM germany)
),
kreis_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'kreis'
      AND country_id = (SELECT id FROM germany)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    kl.country_id,
    kl.id,
    t.id,
    COALESCE(parent_gr.id, parent_state.id),
    ks.display_name,
    ks.admin_code,
    'de_ags_kreis',
    TRUE,
    TRUE,
    ks.source
FROM kreis_level kl
JOIN germany g ON g.id = kl.country_id
JOIN de_kreise_seed ks ON TRUE
JOIN territory t
    ON t.country_id = g.id
   AND t.wikidata_id = ks.territory_wikidata_id
JOIN state_level sl ON sl.country_id = g.id
JOIN admin_territory parent_state
    ON parent_state.country_id = g.id
   AND parent_state.admin_level_id = sl.id
   AND parent_state.admin_code_system = 'de_ags_land'
   AND parent_state.admin_code = ks.parent_state_code
LEFT JOIN government_region_level grl ON grl.country_id = g.id
LEFT JOIN admin_territory parent_gr
    ON parent_gr.country_id = g.id
   AND parent_gr.admin_level_id = grl.id
   AND parent_gr.admin_code_system = 'de_ars_regierungsbezirk'
   AND parent_gr.admin_code = NULLIF(ks.parent_government_region_code, '')
WHERE NULLIF(ks.parent_government_region_code, '') IS NULL
   OR parent_gr.id IS NOT NULL;

DO $$
DECLARE
    expected_count INTEGER;
    actual_count INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_count
    FROM de_kreise_seed;

    SELECT count(*)
    INTO actual_count
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    JOIN country_admin_level cal ON cal.id = at.admin_level_id
    WHERE c.iso_code = 'DE'
      AND cal.code = 'kreis';

    IF actual_count <> expected_count THEN
        RAISE EXCEPTION 'Expected % German Kreis rows, got %', expected_count, actual_count;
    END IF;
END $$;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM germany)
),
kreis_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'kreis'
      AND country_id = (SELECT id FROM germany)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    ms.display_name,
    ms.admin_code,
    'de_ags_municipality',
    TRUE,
    TRUE,
    ms.source
FROM municipality_level ml
JOIN germany g ON g.id = ml.country_id
JOIN de_municipality_seed ms ON TRUE
JOIN territory t
    ON t.country_id = g.id
   AND t.wikidata_id = ms.territory_wikidata_id
JOIN kreis_level kl ON kl.country_id = g.id
JOIN admin_territory parent_at
    ON parent_at.country_id = g.id
   AND parent_at.admin_level_id = kl.id
   AND parent_at.admin_code_system = 'de_ags_kreis'
   AND parent_at.admin_code = ms.parent_kreis_code;

DO $$
DECLARE
    expected_count INTEGER;
    actual_count INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_count
    FROM de_municipality_seed;

    SELECT count(*)
    INTO actual_count
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    JOIN country_admin_level cal ON cal.id = at.admin_level_id
    WHERE c.iso_code = 'DE'
      AND cal.code = 'municipality';

    IF actual_count <> expected_count THEN
        RAISE EXCEPTION 'Expected % German municipality rows, got %', expected_count, actual_count;
    END IF;
END $$;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
)
DELETE FROM admin_territory
USING united_kingdom uk
WHERE admin_territory.country_id = uk.id;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
constituent_country_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'constituent_country'
      AND country_id = (SELECT id FROM united_kingdom)
),
constituent_country_seed(admin_code, display_name, territory_wikidata_id, source) AS (
    VALUES
        ('E92000001', 'England', 'Q21', 'seed.gb_constituent_country'),
        ('N92000002', 'Northern Ireland', 'Q26', 'seed.gb_constituent_country'),
        ('S92000003', 'Scotland', 'Q22', 'seed.gb_constituent_country'),
        ('W92000004', 'Wales', 'Q25', 'seed.gb_constituent_country')
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ccl.country_id,
    ccl.id,
    t.id,
    NULL,
    ccs.display_name,
    ccs.admin_code,
    'gb_ons_ctry25',
    TRUE,
    TRUE,
    ccs.source
FROM constituent_country_level ccl
JOIN united_kingdom uk ON uk.id = ccl.country_id
JOIN constituent_country_seed ccs ON TRUE
JOIN territory t
    ON t.country_id = uk.id
   AND t.wikidata_id = ccs.territory_wikidata_id;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
constituent_country_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'constituent_country'
      AND country_id = (SELECT id FROM united_kingdom)
),
local_authority_district_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'local_authority_district'
      AND country_id = (SELECT id FROM united_kingdom)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ladl.country_id,
    ladl.id,
    t.id,
    parent_at.id,
    lads.display_name,
    lads.admin_code,
    'gb_ons_lad25',
    TRUE,
    TRUE,
    lads.source
FROM local_authority_district_level ladl
JOIN united_kingdom uk ON uk.id = ladl.country_id
JOIN gb_lad_seed lads ON TRUE
JOIN territory t
    ON t.country_id = uk.id
   AND t.wikidata_id = lads.territory_wikidata_id
JOIN constituent_country_level ccl ON ccl.country_id = uk.id
JOIN admin_territory parent_at
    ON parent_at.country_id = uk.id
   AND parent_at.admin_level_id = ccl.id
   AND parent_at.admin_code_system = 'gb_ons_ctry25'
   AND parent_at.admin_code = lads.parent_country_code;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
local_authority_district_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'local_authority_district'
      AND country_id = (SELECT id FROM united_kingdom)
)
INSERT INTO territory (
    name,
    type,
    country_id,
    parent_id,
    wikidata_id,
    telephone_country_code,
    local_dialing_code,
    latitude,
    longitude
)
SELECT
    wards.display_name,
    'region',
    uk.id,
    parent_territory.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM united_kingdom uk
JOIN local_authority_district_level ladl ON ladl.country_id = uk.id
JOIN admin_territory parent_at
    ON parent_at.country_id = uk.id
   AND parent_at.admin_level_id = ladl.id
   AND parent_at.admin_code_system = 'gb_ons_lad25'
JOIN territory parent_territory
    ON parent_territory.id = parent_at.territory_id
JOIN gb_ward_seed wards
    ON wards.parent_lad_code = parent_at.admin_code
LEFT JOIN territory existing
    ON existing.country_id = uk.id
   AND existing.parent_id = parent_territory.id
   AND existing.type = 'region'
   AND existing.name = wards.display_name
   AND existing.wikidata_id IS NULL
WHERE NULLIF(wards.territory_wikidata_id, '') IS NULL
  AND existing.id IS NULL;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
local_authority_district_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'local_authority_district'
      AND country_id = (SELECT id FROM united_kingdom)
),
electoral_ward_division_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'electoral_ward_division'
      AND country_id = (SELECT id FROM united_kingdom)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ewdl.country_id,
    ewdl.id,
    t.id,
    parent_at.id,
    wards.display_name,
    wards.admin_code,
    'gb_ons_wd25',
    TRUE,
    TRUE,
    wards.source
FROM electoral_ward_division_level ewdl
JOIN united_kingdom uk ON uk.id = ewdl.country_id
JOIN gb_ward_seed wards ON TRUE
JOIN local_authority_district_level ladl ON ladl.country_id = uk.id
JOIN admin_territory parent_at
    ON parent_at.country_id = uk.id
   AND parent_at.admin_level_id = ladl.id
   AND parent_at.admin_code_system = 'gb_ons_lad25'
   AND parent_at.admin_code = wards.parent_lad_code
JOIN territory parent_territory
    ON parent_territory.id = parent_at.territory_id
JOIN territory t
    ON t.country_id = uk.id
   AND t.type = 'region'
   AND (
        (NULLIF(wards.territory_wikidata_id, '') IS NOT NULL AND t.wikidata_id = wards.territory_wikidata_id)
        OR (
            NULLIF(wards.territory_wikidata_id, '') IS NULL
            AND t.parent_id = parent_territory.id
            AND t.name = wards.display_name
            AND t.wikidata_id IS NULL
        )
   );

DO $$
DECLARE
    expected_count INTEGER;
    actual_count INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_count
    FROM gb_lad_seed;

    SELECT count(*)
    INTO actual_count
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    JOIN country_admin_level cal ON cal.id = at.admin_level_id
    WHERE c.iso_code = 'GB'
      AND cal.code = 'local_authority_district';

    IF actual_count <> expected_count THEN
        RAISE EXCEPTION 'Expected % UK LAD rows, got %', expected_count, actual_count;
    END IF;
END $$;

DO $$
DECLARE
    expected_count INTEGER;
    actual_count INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_count
    FROM gb_ward_seed;

    SELECT count(*)
    INTO actual_count
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    JOIN country_admin_level cal ON cal.id = at.admin_level_id
    WHERE c.iso_code = 'GB'
      AND cal.code = 'electoral_ward_division';

    IF actual_count <> expected_count THEN
        RAISE EXCEPTION 'Expected % UK ward/division rows, got %', expected_count, actual_count;
    END IF;
END $$;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
)
DELETE FROM admin_territory
USING belgium b
WHERE admin_territory.country_id = b.id;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM belgium)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    rl.country_id,
    rl.id,
    t.id,
    NULL,
    bas.display_name,
    bas.admin_code,
    'be_statbel_refnis_2025',
    TRUE,
    TRUE,
    bas.source
FROM region_level rl
JOIN belgium b ON b.id = rl.country_id
JOIN be_admin_seed bas
    ON bas.level_code = 'region'
JOIN territory t
    ON t.country_id = b.id
   AND t.wikidata_id = bas.territory_wikidata_id;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM belgium)
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM belgium)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    pl.country_id,
    pl.id,
    t.id,
    parent_at.id,
    bas.display_name,
    bas.admin_code,
    'be_statbel_refnis_2025',
    TRUE,
    TRUE,
    bas.source
FROM province_level pl
JOIN belgium b ON b.id = pl.country_id
JOIN be_admin_seed bas
    ON bas.level_code = 'province'
JOIN territory t
    ON t.country_id = b.id
   AND t.wikidata_id = bas.territory_wikidata_id
JOIN region_level rl ON rl.country_id = b.id
JOIN admin_territory parent_at
    ON parent_at.country_id = b.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'be_statbel_refnis_2025'
   AND parent_at.admin_code = bas.parent_admin_code;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM belgium)
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM belgium)
),
arrondissement_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'arrondissement'
      AND country_id = (SELECT id FROM belgium)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    al.country_id,
    al.id,
    t.id,
    COALESCE(parent_province.id, parent_region.id),
    bas.display_name,
    bas.admin_code,
    'be_statbel_refnis_2025',
    TRUE,
    TRUE,
    bas.source
FROM arrondissement_level al
JOIN belgium b ON b.id = al.country_id
JOIN be_admin_seed bas
    ON bas.level_code = 'arrondissement'
JOIN territory t
    ON t.country_id = b.id
   AND t.wikidata_id = bas.territory_wikidata_id
LEFT JOIN province_level pl ON pl.country_id = b.id
LEFT JOIN admin_territory parent_province
    ON parent_province.country_id = b.id
   AND parent_province.admin_level_id = pl.id
   AND parent_province.admin_code_system = 'be_statbel_refnis_2025'
   AND parent_province.admin_code = CASE WHEN bas.parent_level_code = 'province' THEN bas.parent_admin_code ELSE NULL END
LEFT JOIN region_level rl ON rl.country_id = b.id
LEFT JOIN admin_territory parent_region
    ON parent_region.country_id = b.id
   AND parent_region.admin_level_id = rl.id
   AND parent_region.admin_code_system = 'be_statbel_refnis_2025'
   AND parent_region.admin_code = CASE WHEN bas.parent_level_code = 'region' THEN bas.parent_admin_code ELSE NULL END
WHERE (bas.parent_level_code = 'province' AND parent_province.id IS NOT NULL)
   OR (bas.parent_level_code = 'region' AND parent_region.id IS NOT NULL);

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
arrondissement_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'arrondissement'
      AND country_id = (SELECT id FROM belgium)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM belgium)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    bas.display_name,
    bas.admin_code,
    'be_statbel_refnis_2025',
    TRUE,
    TRUE,
    bas.source
FROM municipality_level ml
JOIN belgium b ON b.id = ml.country_id
JOIN be_admin_seed bas
    ON bas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = b.id
   AND t.wikidata_id = bas.territory_wikidata_id
JOIN arrondissement_level al ON al.country_id = b.id
JOIN admin_territory parent_at
    ON parent_at.country_id = b.id
   AND parent_at.admin_level_id = al.id
   AND parent_at.admin_code_system = 'be_statbel_refnis_2025'
   AND parent_at.admin_code = bas.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM be_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'BE';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Belgium admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
)
DELETE FROM admin_territory
USING luxembourg lu
WHERE admin_territory.country_id = lu.id;

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
),
canton_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'canton'
      AND country_id = (SELECT id FROM luxembourg)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    cl.country_id,
    cl.id,
    t.id,
    NULL,
    las.display_name,
    las.admin_code,
    'lu_act_commune_canton_2024',
    TRUE,
    TRUE,
    las.source
FROM canton_level cl
JOIN luxembourg lu ON lu.id = cl.country_id
JOIN lu_admin_seed las
    ON las.level_code = 'canton'
JOIN territory t
    ON t.country_id = lu.id
   AND t.wikidata_id = las.territory_wikidata_id;

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
),
canton_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'canton'
      AND country_id = (SELECT id FROM luxembourg)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM luxembourg)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    las.display_name,
    las.admin_code,
    'lu_act_commune_canton_2024',
    TRUE,
    TRUE,
    las.source
FROM municipality_level ml
JOIN luxembourg lu ON lu.id = ml.country_id
JOIN lu_admin_seed las
    ON las.level_code = 'municipality'
JOIN territory t
    ON t.country_id = lu.id
   AND t.wikidata_id = las.territory_wikidata_id
JOIN canton_level cl ON cl.country_id = lu.id
JOIN admin_territory parent_at
    ON parent_at.country_id = lu.id
   AND parent_at.admin_level_id = cl.id
   AND parent_at.admin_code_system = 'lu_act_commune_canton_2024'
   AND parent_at.admin_code = las.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM lu_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'LU';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Luxembourg admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
)
DELETE FROM admin_territory
USING switzerland ch
WHERE admin_territory.country_id = ch.id;

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
),
canton_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'canton'
      AND country_id = (SELECT id FROM switzerland)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    cl.country_id,
    cl.id,
    t.id,
    NULL,
    cas.display_name,
    cas.admin_code,
    'ch_canton_abbreviation',
    TRUE,
    TRUE,
    cas.source
FROM canton_level cl
JOIN switzerland ch ON ch.id = cl.country_id
JOIN ch_admin_seed cas
    ON cas.level_code = 'canton'
JOIN territory t
    ON t.country_id = ch.id
   AND t.wikidata_id = cas.territory_wikidata_id;

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
),
canton_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'canton'
      AND country_id = (SELECT id FROM switzerland)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM switzerland)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    cas.display_name,
    cas.admin_code,
    'ch_bfs_municipality_code_2026',
    TRUE,
    TRUE,
    cas.source
FROM municipality_level ml
JOIN switzerland ch ON ch.id = ml.country_id
JOIN ch_admin_seed cas
    ON cas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = ch.id
   AND t.wikidata_id = cas.territory_wikidata_id
JOIN canton_level cl ON cl.country_id = ch.id
JOIN admin_territory parent_at
    ON parent_at.country_id = ch.id
   AND parent_at.admin_level_id = cl.id
   AND parent_at.admin_code_system = 'ch_canton_abbreviation'
   AND parent_at.admin_code = cas.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM ch_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'CH';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Switzerland admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
)
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
    aas.territory_wikidata_id,
    aas.territory_name,
    aas.territory_type,
    at.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM austria at
JOIN at_admin_seed aas ON TRUE
LEFT JOIN territory t
    ON t.country_id = at.id
   AND t.wikidata_id = aas.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
)
DELETE FROM admin_territory
USING austria at
WHERE admin_territory.country_id = at.id;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
),
state_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state'
      AND country_id = (SELECT id FROM austria)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    sl.country_id,
    sl.id,
    t.id,
    NULL,
    aas.display_name,
    aas.admin_code,
    'at_statistik_austria_bundesland_code',
    TRUE,
    TRUE,
    aas.source
FROM state_level sl
JOIN austria at ON at.id = sl.country_id
JOIN at_admin_seed aas
    ON aas.level_code = 'state'
JOIN territory t
    ON t.country_id = at.id
   AND t.wikidata_id = aas.territory_wikidata_id;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
),
state_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state'
      AND country_id = (SELECT id FROM austria)
),
district_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'district'
      AND country_id = (SELECT id FROM austria)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    dl.country_id,
    dl.id,
    t.id,
    parent_at.id,
    aas.display_name,
    aas.admin_code,
    'at_statistik_austria_bkz_2026',
    TRUE,
    TRUE,
    aas.source
FROM district_level dl
JOIN austria at ON at.id = dl.country_id
JOIN at_admin_seed aas
    ON aas.level_code = 'district'
JOIN territory t
    ON t.country_id = at.id
   AND t.wikidata_id = aas.territory_wikidata_id
JOIN state_level sl ON sl.country_id = at.id
JOIN admin_territory parent_at
    ON parent_at.country_id = at.id
   AND parent_at.admin_level_id = sl.id
   AND parent_at.admin_code_system = 'at_statistik_austria_bundesland_code'
   AND parent_at.admin_code = aas.parent_admin_code;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
),
district_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'district'
      AND country_id = (SELECT id FROM austria)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM austria)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    aas.display_name,
    aas.admin_code,
    'at_statistik_austria_gkz_2026',
    TRUE,
    TRUE,
    aas.source
FROM municipality_level ml
JOIN austria at ON at.id = ml.country_id
JOIN at_admin_seed aas
    ON aas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = at.id
   AND t.wikidata_id = aas.territory_wikidata_id
JOIN district_level dl ON dl.country_id = at.id
JOIN admin_territory parent_at
    ON parent_at.country_id = at.id
   AND parent_at.admin_level_id = dl.id
   AND parent_at.admin_code_system = 'at_statistik_austria_bkz_2026'
   AND parent_at.admin_code = aas.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM at_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'AT';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Austria admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
)
DELETE FROM admin_territory
USING denmark dk
WHERE admin_territory.country_id = dk.id;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM denmark)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    rl.country_id,
    rl.id,
    t.id,
    NULL,
    das.display_name,
    das.admin_code,
    'dk_dst_regionkode_2007',
    TRUE,
    TRUE,
    das.source
FROM region_level rl
JOIN denmark dk ON dk.id = rl.country_id
JOIN dk_admin_seed das
    ON das.level_code = 'region'
JOIN territory t
    ON t.country_id = dk.id
   AND t.wikidata_id = das.territory_wikidata_id;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM denmark)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM denmark)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    das.display_name,
    das.admin_code,
    'dk_dst_kommunekode_2007',
    TRUE,
    TRUE,
    das.source
FROM municipality_level ml
JOIN denmark dk ON dk.id = ml.country_id
JOIN dk_admin_seed das
    ON das.level_code = 'municipality'
JOIN territory t
    ON t.country_id = dk.id
   AND t.wikidata_id = das.territory_wikidata_id
JOIN region_level rl ON rl.country_id = dk.id
JOIN admin_territory parent_at
    ON parent_at.country_id = dk.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'dk_dst_regionkode_2007'
   AND parent_at.admin_code = das.parent_admin_code;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM denmark)
),
state_managed_area_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'state_managed_area'
      AND country_id = (SELECT id FROM denmark)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    smal.country_id,
    smal.id,
    t.id,
    parent_at.id,
    das.display_name,
    das.admin_code,
    'dk_dst_kommunekode_2007',
    TRUE,
    TRUE,
    das.source
FROM state_managed_area_level smal
JOIN denmark dk ON dk.id = smal.country_id
JOIN dk_admin_seed das
    ON das.level_code = 'state_managed_area'
JOIN territory t
    ON t.country_id = dk.id
   AND t.wikidata_id = das.territory_wikidata_id
JOIN region_level rl ON rl.country_id = dk.id
JOIN admin_territory parent_at
    ON parent_at.country_id = dk.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'dk_dst_regionkode_2007'
   AND parent_at.admin_code = das.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM dk_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'DK';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Denmark admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
),
province_seed AS (
    SELECT *
    FROM nl_admin_seed
    WHERE level_code = 'province'
)
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
    ps.territory_wikidata_id,
    ps.territory_name,
    ps.territory_type,
    nl.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM netherlands nl
JOIN province_seed ps ON TRUE
ON CONFLICT (wikidata_id) DO UPDATE
SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    country_id = EXCLUDED.country_id,
    parent_id = EXCLUDED.parent_id,
    telephone_country_code = EXCLUDED.telephone_country_code,
    local_dialing_code = EXCLUDED.local_dialing_code,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
),
municipality_seed AS (
    SELECT *
    FROM nl_admin_seed
    WHERE level_code = 'municipality'
),
province_seed AS (
    SELECT *
    FROM nl_admin_seed
    WHERE level_code = 'province'
)
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
    ms.territory_wikidata_id,
    ms.territory_name,
    ms.territory_type,
    nl.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM netherlands nl
JOIN municipality_seed ms ON TRUE
LEFT JOIN province_seed ps
    ON ps.admin_code = NULLIF(ms.parent_admin_code, '')
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = ps.territory_wikidata_id
ON CONFLICT (wikidata_id) DO UPDATE
SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    country_id = EXCLUDED.country_id,
    parent_id = EXCLUDED.parent_id,
    telephone_country_code = EXCLUDED.telephone_country_code,
    local_dialing_code = EXCLUDED.local_dialing_code,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
)
DELETE FROM admin_territory
USING netherlands nl
WHERE admin_territory.country_id = nl.id;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM netherlands)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    pl.country_id,
    pl.id,
    t.id,
    NULL,
    nas.display_name,
    nas.admin_code,
    'nl_cbs_province_code_2026',
    TRUE,
    TRUE,
    nas.source
FROM province_level pl
JOIN netherlands nl ON nl.id = pl.country_id
JOIN nl_admin_seed nas
    ON nas.level_code = 'province'
JOIN territory t
    ON t.country_id = nl.id
   AND t.wikidata_id = nas.territory_wikidata_id;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM netherlands)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM netherlands)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    nas.display_name,
    nas.admin_code,
    'nl_cbs_gemeentecode_2026',
    TRUE,
    TRUE,
    nas.source
FROM municipality_level ml
JOIN netherlands nl ON nl.id = ml.country_id
JOIN nl_admin_seed nas
    ON nas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = nl.id
   AND t.wikidata_id = nas.territory_wikidata_id
LEFT JOIN province_level pl ON pl.country_id = nl.id
LEFT JOIN admin_territory parent_at
    ON parent_at.country_id = nl.id
   AND parent_at.admin_level_id = pl.id
   AND parent_at.admin_code_system = 'nl_cbs_province_code_2026'
   AND parent_at.admin_code = NULLIF(nas.parent_admin_code, '')
WHERE NULLIF(nas.parent_admin_code, '') IS NULL
   OR parent_at.id IS NOT NULL;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM nl_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'NL';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Netherlands admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
region_seed AS (
    SELECT *
    FROM it_admin_seed
    WHERE level_code = 'region'
)
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
    rs.territory_wikidata_id,
    rs.territory_name,
    rs.territory_type,
    it.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM italy it
JOIN region_seed rs ON TRUE
LEFT JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = rs.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
region_seed AS (
    SELECT *
    FROM it_admin_seed
    WHERE level_code = 'region'
),
province_seed AS (
    SELECT *
    FROM it_admin_seed
    WHERE level_code = 'province_or_equivalent'
)
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
    ps.territory_wikidata_id,
    ps.territory_name,
    ps.territory_type,
    it.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM italy it
JOIN province_seed ps ON TRUE
LEFT JOIN region_seed rs
    ON rs.admin_code = ps.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = rs.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = ps.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
province_seed AS (
    SELECT *
    FROM it_admin_seed
    WHERE level_code = 'province_or_equivalent'
),
municipality_seed AS (
    SELECT *
    FROM it_admin_seed
    WHERE level_code = 'municipality'
)
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
    ms.territory_wikidata_id,
    ms.territory_name,
    ms.territory_type,
    it.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM italy it
JOIN municipality_seed ms ON TRUE
LEFT JOIN province_seed ps
    ON ps.admin_code = ms.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = ps.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = ms.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
)
DELETE FROM admin_territory
USING italy it
WHERE admin_territory.country_id = it.id;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM italy)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    rl.country_id,
    rl.id,
    t.id,
    NULL,
    ias.display_name,
    ias.admin_code,
    'it_istat_region_code_2026',
    TRUE,
    TRUE,
    ias.source
FROM region_level rl
JOIN italy it ON it.id = rl.country_id
JOIN it_admin_seed ias
    ON ias.level_code = 'region'
JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = ias.territory_wikidata_id;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
region_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'region'
      AND country_id = (SELECT id FROM italy)
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province_or_equivalent'
      AND country_id = (SELECT id FROM italy)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    pl.country_id,
    pl.id,
    t.id,
    parent_at.id,
    ias.display_name,
    ias.admin_code,
    'it_istat_uts_code_2026',
    TRUE,
    TRUE,
    ias.source
FROM province_level pl
JOIN italy it ON it.id = pl.country_id
JOIN it_admin_seed ias
    ON ias.level_code = 'province_or_equivalent'
JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = ias.territory_wikidata_id
JOIN region_level rl ON rl.country_id = it.id
JOIN admin_territory parent_at
    ON parent_at.country_id = it.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'it_istat_region_code_2026'
   AND parent_at.admin_code = ias.parent_admin_code;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province_or_equivalent'
      AND country_id = (SELECT id FROM italy)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM italy)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    ias.display_name,
    ias.admin_code,
    'it_istat_municipality_code_2026',
    TRUE,
    TRUE,
    ias.source
FROM municipality_level ml
JOIN italy it ON it.id = ml.country_id
JOIN it_admin_seed ias
    ON ias.level_code = 'municipality'
JOIN territory t
    ON t.country_id = it.id
   AND t.wikidata_id = ias.territory_wikidata_id
JOIN province_level pl ON pl.country_id = it.id
JOIN admin_territory parent_at
    ON parent_at.country_id = it.id
   AND parent_at.admin_level_id = pl.id
   AND parent_at.admin_code_system = 'it_istat_uts_code_2026'
   AND parent_at.admin_code = ias.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM it_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'IT';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Italy admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH ireland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IE'
)
DELETE FROM admin_territory
USING ireland i
WHERE admin_territory.country_id = i.id;

WITH ireland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IE'
),
county_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'county'
      AND country_id = (SELECT id FROM ireland)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    cl.country_id,
    cl.id,
    t.id,
    NULL,
    ies.display_name,
    ies.admin_code,
    'ie_iso_3166_2',
    TRUE,
    TRUE,
    ies.source
FROM county_level cl
JOIN ireland i ON i.id = cl.country_id
JOIN ie_admin_seed ies ON TRUE
JOIN territory t
    ON t.country_id = i.id
   AND t.wikidata_id = ies.territory_wikidata_id;

DO $$
DECLARE
    expected_count INTEGER;
    actual_count INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_count
    FROM ie_admin_seed;

    SELECT count(*)
    INTO actual_count
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'IE';

    IF actual_count <> expected_count THEN
        RAISE EXCEPTION 'Expected % Ireland admin rows, got %', expected_count, actual_count;
    END IF;
END $$;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
top_level_seed AS (
    SELECT *
    FROM es_admin_seed
    WHERE level_code = 'autonomous_community_or_city'
)
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
    tls.territory_wikidata_id,
    tls.territory_name,
    tls.territory_type,
    es.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM spain es
JOIN top_level_seed tls ON TRUE
LEFT JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = tls.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
top_level_seed AS (
    SELECT *
    FROM es_admin_seed
    WHERE level_code = 'autonomous_community_or_city'
),
province_seed AS (
    SELECT *
    FROM es_admin_seed
    WHERE level_code = 'province'
)
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
    ps.territory_wikidata_id,
    ps.territory_name,
    ps.territory_type,
    es.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM spain es
JOIN province_seed ps ON TRUE
LEFT JOIN top_level_seed tls
    ON tls.admin_code = ps.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = tls.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = ps.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
province_seed AS (
    SELECT *
    FROM es_admin_seed
    WHERE level_code = 'province'
),
municipality_seed AS (
    SELECT *
    FROM es_admin_seed
    WHERE level_code = 'municipality'
)
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
    ms.territory_wikidata_id,
    ms.territory_name,
    ms.territory_type,
    es.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM spain es
JOIN municipality_seed ms ON TRUE
LEFT JOIN province_seed ps
    ON ps.admin_code = ms.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = ps.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = ms.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
)
DELETE FROM admin_territory
USING spain es
WHERE admin_territory.country_id = es.id;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
top_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'autonomous_community_or_city'
      AND country_id = (SELECT id FROM spain)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    tl.country_id,
    tl.id,
    t.id,
    NULL,
    eas.display_name,
    eas.admin_code,
    'es_ine_autonomous_community_code_2026',
    TRUE,
    TRUE,
    eas.source
FROM top_level tl
JOIN spain es ON es.id = tl.country_id
JOIN es_admin_seed eas
    ON eas.level_code = 'autonomous_community_or_city'
JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = eas.territory_wikidata_id;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
top_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'autonomous_community_or_city'
      AND country_id = (SELECT id FROM spain)
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM spain)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    pl.country_id,
    pl.id,
    t.id,
    parent_at.id,
    eas.display_name,
    eas.admin_code,
    'es_ine_province_code_2026',
    TRUE,
    TRUE,
    eas.source
FROM province_level pl
JOIN spain es ON es.id = pl.country_id
JOIN es_admin_seed eas
    ON eas.level_code = 'province'
JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = eas.territory_wikidata_id
JOIN top_level tl ON tl.country_id = es.id
JOIN admin_territory parent_at
    ON parent_at.country_id = es.id
   AND parent_at.admin_level_id = tl.id
   AND parent_at.admin_code_system = 'es_ine_autonomous_community_code_2026'
   AND parent_at.admin_code = eas.parent_admin_code;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
province_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'province'
      AND country_id = (SELECT id FROM spain)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM spain)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    eas.display_name,
    eas.admin_code,
    'es_ine_municipality_code_2026',
    TRUE,
    TRUE,
    eas.source
FROM municipality_level ml
JOIN spain es ON es.id = ml.country_id
JOIN es_admin_seed eas
    ON eas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = es.id
   AND t.wikidata_id = eas.territory_wikidata_id
JOIN province_level pl ON pl.country_id = es.id
JOIN admin_territory parent_at
    ON parent_at.country_id = es.id
   AND parent_at.admin_level_id = pl.id
   AND parent_at.admin_code_system = 'es_ine_province_code_2026'
   AND parent_at.admin_code = eas.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM es_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'ES';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Spain admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
top_level_seed AS (
    SELECT *
    FROM pt_admin_seed
    WHERE level_code = 'district_or_island'
)
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
    tls.territory_wikidata_id,
    tls.territory_name,
    tls.territory_type,
    pt.id,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
FROM portugal pt
JOIN top_level_seed tls ON TRUE
LEFT JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = tls.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
top_level_seed AS (
    SELECT *
    FROM pt_admin_seed
    WHERE level_code = 'district_or_island'
),
municipality_seed AS (
    SELECT *
    FROM pt_admin_seed
    WHERE level_code = 'municipality'
)
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
    ms.territory_wikidata_id,
    ms.territory_name,
    ms.territory_type,
    pt.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM portugal pt
JOIN municipality_seed ms ON TRUE
LEFT JOIN top_level_seed tls
    ON tls.admin_code = ms.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = tls.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = ms.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
municipality_seed AS (
    SELECT *
    FROM pt_admin_seed
    WHERE level_code = 'municipality'
),
civil_parish_seed AS (
    SELECT *
    FROM pt_admin_seed
    WHERE level_code = 'civil_parish'
)
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
    cps.territory_wikidata_id,
    cps.territory_name,
    cps.territory_type,
    pt.id,
    parent_t.id,
    NULL,
    NULL,
    NULL,
    NULL
FROM portugal pt
JOIN civil_parish_seed cps ON TRUE
LEFT JOIN municipality_seed ms
    ON ms.admin_code = cps.parent_admin_code
LEFT JOIN territory parent_t
    ON parent_t.wikidata_id = ms.territory_wikidata_id
LEFT JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = cps.territory_wikidata_id
WHERE t.id IS NULL
ON CONFLICT (wikidata_id) DO NOTHING;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
)
DELETE FROM admin_territory
USING portugal pt
WHERE admin_territory.country_id = pt.id;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
top_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'district_or_island'
      AND country_id = (SELECT id FROM portugal)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    tl.country_id,
    tl.id,
    t.id,
    NULL,
    pas.display_name,
    pas.admin_code,
    'pt_dgt_au_parent_code',
    TRUE,
    TRUE,
    pas.source
FROM top_level tl
JOIN portugal pt ON pt.id = tl.country_id
JOIN pt_admin_seed pas
    ON pas.level_code = 'district_or_island'
JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = pas.territory_wikidata_id;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
top_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'district_or_island'
      AND country_id = (SELECT id FROM portugal)
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM portugal)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    ml.country_id,
    ml.id,
    t.id,
    parent_at.id,
    pas.display_name,
    pas.admin_code,
    'pt_dgt_au_municipality_code',
    TRUE,
    TRUE,
    pas.source
FROM municipality_level ml
JOIN portugal pt ON pt.id = ml.country_id
JOIN pt_admin_seed pas
    ON pas.level_code = 'municipality'
JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = pas.territory_wikidata_id
JOIN top_level tl ON tl.country_id = pt.id
JOIN admin_territory parent_at
    ON parent_at.country_id = pt.id
   AND parent_at.admin_level_id = tl.id
   AND parent_at.admin_code_system = 'pt_dgt_au_parent_code'
   AND parent_at.admin_code = pas.parent_admin_code;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
municipality_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'municipality'
      AND country_id = (SELECT id FROM portugal)
),
civil_parish_level AS (
    SELECT id, country_id
    FROM country_admin_level
    WHERE code = 'civil_parish'
      AND country_id = (SELECT id FROM portugal)
)
INSERT INTO admin_territory (
    country_id,
    admin_level_id,
    territory_id,
    parent_admin_territory_id,
    display_name,
    admin_code,
    admin_code_system,
    is_current,
    is_official,
    source
)
SELECT
    cpl.country_id,
    cpl.id,
    t.id,
    parent_at.id,
    pas.display_name,
    pas.admin_code,
    'pt_dgt_au_civil_parish_code',
    TRUE,
    TRUE,
    pas.source
FROM civil_parish_level cpl
JOIN portugal pt ON pt.id = cpl.country_id
JOIN pt_admin_seed pas
    ON pas.level_code = 'civil_parish'
JOIN territory t
    ON t.country_id = pt.id
   AND t.wikidata_id = pas.territory_wikidata_id
JOIN municipality_level ml ON ml.country_id = pt.id
JOIN admin_territory parent_at
    ON parent_at.country_id = pt.id
   AND parent_at.admin_level_id = ml.id
   AND parent_at.admin_code_system = 'pt_dgt_au_municipality_code'
   AND parent_at.admin_code = pas.parent_admin_code;

DO $$
DECLARE
    expected_total INTEGER;
    actual_total INTEGER;
BEGIN
    SELECT count(*)
    INTO expected_total
    FROM pt_admin_seed;

    SELECT count(*)
    INTO actual_total
    FROM admin_territory at
    JOIN country c ON c.id = at.country_id
    WHERE c.iso_code = 'PT';

    IF actual_total <> expected_total THEN
        RAISE EXCEPTION 'Expected % Portugal admin rows, got %', expected_total, actual_total;
    END IF;
END $$;

COMMIT;
SQL
} | "${PSQL[@]}"

FR_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'FR'")"
DE_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'DE'")"
GB_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'GB'")"
IE_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'IE'")"
ES_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'ES'")"
PT_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'PT'")"
BE_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'BE'")"
LU_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'LU'")"
CH_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'CH'")"
AT_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'AT'")"
NL_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'NL'")"
DK_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'DK'")"
IT_COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'IT'")"
echo "Administrative hierarchy sync completed (${FR_COUNT} French rows, ${DE_COUNT} German rows, ${GB_COUNT} UK rows, ${IE_COUNT} Ireland rows, ${ES_COUNT} Spain rows, ${PT_COUNT} Portugal rows, ${BE_COUNT} Belgium rows, ${LU_COUNT} Luxembourg rows, ${CH_COUNT} Switzerland rows, ${AT_COUNT} Austria rows, ${DK_COUNT} Denmark rows, ${NL_COUNT} Netherlands rows, ${IT_COUNT} Italy rows)."

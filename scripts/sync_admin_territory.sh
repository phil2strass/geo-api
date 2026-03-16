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

echo "Synchronizing administrative hierarchy for France..."
"${PSQL[@]}" <<'SQL'
\set ON_ERROR_STOP on
BEGIN;

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
region_seed(admin_code, display_name, territory_name, territory_type, source) AS (
    VALUES
        ('01', 'Guadeloupe', 'Guadeloupe', 'overseas_region', 'seed.fr_admin_region'),
        ('02', 'Martinique', 'Martinique', 'overseas_region', 'seed.fr_admin_region'),
        ('03', 'Guyane', 'French Guiana', 'overseas_region', 'seed.fr_admin_region'),
        ('04', 'La Réunion', 'Réunion', 'overseas_region', 'seed.fr_admin_region'),
        ('06', 'Mayotte', 'Mayotte', 'overseas_region', 'seed.fr_admin_region'),
        ('11', 'Île-de-France', 'Île-de-France', 'region', 'seed.fr_admin_region'),
        ('24', 'Centre-Val de Loire', 'Centre-Val de Loire', 'region', 'seed.fr_admin_region'),
        ('27', 'Bourgogne-Franche-Comté', 'Bourgogne-Franche-Comté', 'region', 'seed.fr_admin_region'),
        ('28', 'Normandie', 'Normandy', 'region', 'seed.fr_admin_region'),
        ('32', 'Hauts-de-France', 'Hauts-de-France', 'region', 'seed.fr_admin_region'),
        ('44', 'Grand Est', 'Grand Est', 'region', 'seed.fr_admin_region'),
        ('52', 'Pays de la Loire', 'Pays de la Loire', 'region', 'seed.fr_admin_region'),
        ('53', 'Bretagne', 'Brittany', 'region', 'seed.fr_admin_region'),
        ('75', 'Nouvelle-Aquitaine', 'Nouvelle-Aquitaine', 'region', 'seed.fr_admin_region'),
        ('76', 'Occitanie', 'Occitania', 'region', 'seed.fr_admin_region'),
        ('84', 'Auvergne-Rhône-Alpes', 'Auvergne-Rhône-Alpes', 'region', 'seed.fr_admin_region'),
        ('93', 'Provence-Alpes-Côte d''Azur', 'Provence-Alpes-Côte d''Azur', 'region', 'seed.fr_admin_region'),
        ('94', 'Corse', 'Corsica', 'region', 'seed.fr_admin_region')
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
   AND t.name = rs.territory_name
   AND t.type = rs.territory_type;

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
department_seed(admin_code, display_name, territory_name, territory_type, parent_region_code, source) AS (
    VALUES
        ('01', 'Ain', 'Ain', 'department', '84', 'seed.fr_admin_department'),
        ('02', 'Aisne', 'Aisne', 'department', '32', 'seed.fr_admin_department'),
        ('03', 'Allier', 'Allier', 'department', '84', 'seed.fr_admin_department'),
        ('04', 'Alpes-de-Haute-Provence', 'Alpes-de-Haute-Provence', 'department', '93', 'seed.fr_admin_department'),
        ('05', 'Hautes-Alpes', 'Hautes-Alpes', 'department', '93', 'seed.fr_admin_department'),
        ('06', 'Alpes-Maritimes', 'Alpes-Maritimes', 'department', '93', 'seed.fr_admin_department'),
        ('07', 'Ardèche', 'Ardèche', 'department', '84', 'seed.fr_admin_department'),
        ('08', 'Ardennes', 'Ardennes', 'department', '44', 'seed.fr_admin_department'),
        ('09', 'Ariège', 'Ariège', 'department', '76', 'seed.fr_admin_department'),
        ('10', 'Aube', 'Aube', 'department', '44', 'seed.fr_admin_department'),
        ('11', 'Aude', 'Aude', 'department', '76', 'seed.fr_admin_department'),
        ('12', 'Aveyron', 'Aveyron', 'department', '76', 'seed.fr_admin_department'),
        ('13', 'Bouches-du-Rhône', 'Bouches-du-Rhône', 'department', '93', 'seed.fr_admin_department'),
        ('14', 'Calvados', 'Calvados', 'department', '28', 'seed.fr_admin_department'),
        ('15', 'Cantal', 'Cantal', 'department', '84', 'seed.fr_admin_department'),
        ('16', 'Charente', 'Charente', 'department', '75', 'seed.fr_admin_department'),
        ('17', 'Charente-Maritime', 'Charente-Maritime', 'department', '75', 'seed.fr_admin_department'),
        ('18', 'Cher', 'Cher', 'department', '24', 'seed.fr_admin_department'),
        ('19', 'Corrèze', 'Corrèze', 'department', '75', 'seed.fr_admin_department'),
        ('2A', 'Corse-du-Sud', 'Corse-du-Sud', 'department', '94', 'seed.fr_admin_department'),
        ('2B', 'Haute-Corse', 'Haute-Corse', 'department', '94', 'seed.fr_admin_department'),
        ('21', 'Côte-d''Or', 'Côte-d’Or', 'department', '27', 'seed.fr_admin_department'),
        ('22', 'Côtes-d''Armor', 'Côtes-d''Armor', 'department', '53', 'seed.fr_admin_department'),
        ('23', 'Creuse', 'Creuse', 'department', '75', 'seed.fr_admin_department'),
        ('24', 'Dordogne', 'Dordogne', 'department', '75', 'seed.fr_admin_department'),
        ('25', 'Doubs', 'Doubs', 'department', '27', 'seed.fr_admin_department'),
        ('26', 'Drôme', 'Drôme', 'department', '84', 'seed.fr_admin_department'),
        ('27', 'Eure', 'Eure', 'department', '28', 'seed.fr_admin_department'),
        ('28', 'Eure-et-Loir', 'Eure-et-Loir', 'department', '24', 'seed.fr_admin_department'),
        ('29', 'Finistère', 'Finistère', 'department', '53', 'seed.fr_admin_department'),
        ('30', 'Gard', 'Gard', 'department', '76', 'seed.fr_admin_department'),
        ('31', 'Haute-Garonne', 'Haute-Garonne', 'department', '76', 'seed.fr_admin_department'),
        ('32', 'Gers', 'Gers', 'department', '76', 'seed.fr_admin_department'),
        ('33', 'Gironde', 'Gironde', 'department', '75', 'seed.fr_admin_department'),
        ('34', 'Hérault', 'Hérault', 'department', '76', 'seed.fr_admin_department'),
        ('35', 'Ille-et-Vilaine', 'Ille-et-Vilaine', 'department', '53', 'seed.fr_admin_department'),
        ('36', 'Indre', 'Indre', 'department', '24', 'seed.fr_admin_department'),
        ('37', 'Indre-et-Loire', 'Indre-et-Loire', 'department', '24', 'seed.fr_admin_department'),
        ('38', 'Isère', 'Isère', 'department', '84', 'seed.fr_admin_department'),
        ('39', 'Jura', 'Jura', 'department', '27', 'seed.fr_admin_department'),
        ('40', 'Landes', 'Landes', 'department', '75', 'seed.fr_admin_department'),
        ('41', 'Loir-et-Cher', 'Loir-et-Cher', 'department', '24', 'seed.fr_admin_department'),
        ('42', 'Loire', 'Loire', 'department', '84', 'seed.fr_admin_department'),
        ('43', 'Haute-Loire', 'Haute-Loire', 'department', '84', 'seed.fr_admin_department'),
        ('44', 'Loire-Atlantique', 'Loire-Atlantique', 'department', '52', 'seed.fr_admin_department'),
        ('45', 'Loiret', 'Loiret', 'department', '24', 'seed.fr_admin_department'),
        ('46', 'Lot', 'Lot', 'department', '76', 'seed.fr_admin_department'),
        ('47', 'Lot-et-Garonne', 'Lot-et-Garonne', 'department', '75', 'seed.fr_admin_department'),
        ('48', 'Lozère', 'Lozère', 'department', '76', 'seed.fr_admin_department'),
        ('49', 'Maine-et-Loire', 'Maine-et-Loire', 'department', '52', 'seed.fr_admin_department'),
        ('50', 'Manche', 'Manche', 'department', '28', 'seed.fr_admin_department'),
        ('51', 'Marne', 'Marne', 'department', '44', 'seed.fr_admin_department'),
        ('52', 'Haute-Marne', 'Haute-Marne', 'department', '44', 'seed.fr_admin_department'),
        ('53', 'Mayenne', 'Mayenne', 'department', '52', 'seed.fr_admin_department'),
        ('54', 'Meurthe-et-Moselle', 'Meurthe-et-Moselle', 'department', '44', 'seed.fr_admin_department'),
        ('55', 'Meuse', 'Meuse', 'department', '44', 'seed.fr_admin_department'),
        ('56', 'Morbihan', 'Morbihan', 'department', '53', 'seed.fr_admin_department'),
        ('57', 'Moselle', 'Moselle', 'department', '44', 'seed.fr_admin_department'),
        ('58', 'Nièvre', 'Nièvre', 'department', '27', 'seed.fr_admin_department'),
        ('59', 'Nord', 'Nord', 'department', '32', 'seed.fr_admin_department'),
        ('60', 'Oise', 'Oise', 'department', '32', 'seed.fr_admin_department'),
        ('61', 'Orne', 'Orne', 'department', '28', 'seed.fr_admin_department'),
        ('62', 'Pas-de-Calais', 'Pas-de-Calais', 'department', '32', 'seed.fr_admin_department'),
        ('63', 'Puy-de-Dôme', 'Puy-de-Dôme', 'department', '84', 'seed.fr_admin_department'),
        ('64', 'Pyrénées-Atlantiques', 'Pyrénées-Atlantiques', 'department', '75', 'seed.fr_admin_department'),
        ('65', 'Hautes-Pyrénées', 'Hautes-Pyrénées', 'department', '76', 'seed.fr_admin_department'),
        ('66', 'Pyrénées-Orientales', 'Pyrénées-Orientales', 'department', '76', 'seed.fr_admin_department'),
        ('67', 'Bas-Rhin', 'Bas-Rhin', 'department', '44', 'seed.fr_admin_department'),
        ('68', 'Haut-Rhin', 'Haut-Rhin', 'department', '44', 'seed.fr_admin_department'),
        ('69', 'Rhône', 'Rhône', 'department', '84', 'seed.fr_admin_department'),
        ('70', 'Haute-Saône', 'Haute-Saône', 'department', '27', 'seed.fr_admin_department'),
        ('71', 'Saône-et-Loire', 'Saône-et-Loire', 'department', '27', 'seed.fr_admin_department'),
        ('72', 'Sarthe', 'Sarthe', 'department', '52', 'seed.fr_admin_department'),
        ('73', 'Savoie', 'Savoie', 'department', '84', 'seed.fr_admin_department'),
        ('74', 'Haute-Savoie', 'Haute-Savoie', 'department', '84', 'seed.fr_admin_department'),
        ('75', 'Paris', 'Paris Department', 'department', '11', 'seed.fr_admin_department'),
        ('76', 'Seine-Maritime', 'Seine-Maritime', 'department', '28', 'seed.fr_admin_department'),
        ('77', 'Seine-et-Marne', 'Seine-et-Marne', 'department', '11', 'seed.fr_admin_department'),
        ('78', 'Yvelines', 'Yvelines', 'department', '11', 'seed.fr_admin_department'),
        ('79', 'Deux-Sèvres', 'Deux-Sèvres', 'department', '75', 'seed.fr_admin_department'),
        ('80', 'Somme', 'Somme', 'department', '32', 'seed.fr_admin_department'),
        ('81', 'Tarn', 'Tarn', 'department', '76', 'seed.fr_admin_department'),
        ('82', 'Tarn-et-Garonne', 'Tarn-et-Garonne', 'department', '76', 'seed.fr_admin_department'),
        ('83', 'Var', 'Var', 'department', '93', 'seed.fr_admin_department'),
        ('84', 'Vaucluse', 'Vaucluse', 'department', '93', 'seed.fr_admin_department'),
        ('85', 'Vendée', 'Vendée', 'department', '52', 'seed.fr_admin_department'),
        ('86', 'Vienne', 'Vienne', 'department', '75', 'seed.fr_admin_department'),
        ('87', 'Haute-Vienne', 'Haute-Vienne', 'department', '75', 'seed.fr_admin_department'),
        ('88', 'Vosges', 'Vosges', 'department', '44', 'seed.fr_admin_department'),
        ('89', 'Yonne', 'Yonne', 'department', '27', 'seed.fr_admin_department'),
        ('90', 'Territoire de Belfort', 'Territoire de Belfort', 'department', '27', 'seed.fr_admin_department'),
        ('91', 'Essonne', 'Essonne', 'department', '11', 'seed.fr_admin_department'),
        ('92', 'Hauts-de-Seine', 'Hauts-de-Seine', 'department', '11', 'seed.fr_admin_department'),
        ('93', 'Seine-Saint-Denis', 'Seine-Saint-Denis', 'department', '11', 'seed.fr_admin_department'),
        ('94', 'Val-de-Marne', 'Val-de-Marne', 'department', '11', 'seed.fr_admin_department'),
        ('95', 'Val-d''Oise', 'Val-d''Oise', 'department', '11', 'seed.fr_admin_department'),
        ('971', 'Guadeloupe', 'Guadeloupe', 'overseas_region', '01', 'seed.fr_admin_department'),
        ('972', 'Martinique', 'Martinique', 'overseas_region', '02', 'seed.fr_admin_department'),
        ('973', 'Guyane', 'French Guiana', 'overseas_region', '03', 'seed.fr_admin_department'),
        ('974', 'La Réunion', 'Réunion', 'overseas_region', '04', 'seed.fr_admin_department'),
        ('976', 'Mayotte', 'Mayotte', 'overseas_region', '06', 'seed.fr_admin_department')
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
   AND t.name = ds.territory_name
   AND t.type = ds.territory_type
JOIN region_level rl ON rl.country_id = f.id
JOIN admin_territory parent_at
    ON parent_at.country_id = f.id
   AND parent_at.admin_level_id = rl.id
   AND parent_at.admin_code_system = 'fr_insee'
   AND parent_at.admin_code = ds.parent_region_code;

COMMIT;
SQL

COUNT="$("${PSQL[@]}" -qtAX -c "SELECT count(*) FROM admin_territory at JOIN country c ON c.id = at.country_id WHERE c.iso_code = 'FR'")"
echo "Administrative hierarchy sync completed (${COUNT} French rows)."

--liquibase formatted sql

--changeset codex:37-override-italy-admin-levels dbms:postgresql
--comment Replace the inferred Italy hierarchy with curated official regions, ISTAT province-or-equivalent units and municipalities.

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
)
DELETE FROM country_admin_level cal
USING italy it
WHERE cal.country_id = it.id;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'region', 'Region', 'region'),
        (2, 'province_or_equivalent', 'Province or Equivalent', 'province'),
        (3, 'municipality', 'Municipality', 'municipality')
)
INSERT INTO country_admin_level (
    country_id,
    level_number,
    code,
    label,
    default_territory_type_code,
    parent_level_id,
    is_current
)
SELECT
    it.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM italy it
CROSS JOIN seed s;

WITH italy AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IT'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('province_or_equivalent', 'region'),
        ('municipality', 'province_or_equivalent')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM italy it
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = it.id
   AND parent.code = ps.parent_code
WHERE child.country_id = it.id
  AND child.code = ps.child_code;

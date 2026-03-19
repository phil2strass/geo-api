--liquibase formatted sql

--changeset codex:35-override-switzerland-admin-levels dbms:postgresql
--comment Replace the inferred Switzerland hierarchy with curated official cantons and municipalities.

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
)
DELETE FROM country_admin_level cal
USING switzerland ch
WHERE cal.country_id = ch.id;

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'canton', 'Canton', 'region'),
        (2, 'municipality', 'Municipality', 'municipality')
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
    ch.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM switzerland ch
CROSS JOIN seed s;

WITH switzerland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'CH'
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM switzerland ch
JOIN country_admin_level parent
    ON parent.country_id = ch.id
   AND parent.code = 'canton'
WHERE child.country_id = ch.id
  AND child.code = 'municipality';

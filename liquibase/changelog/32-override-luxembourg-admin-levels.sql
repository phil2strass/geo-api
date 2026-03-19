--liquibase formatted sql

--changeset codex:32-override-luxembourg-admin-levels dbms:postgresql
--comment Replace the inferred Luxembourg hierarchy with curated official cantons and municipalities.

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
)
DELETE FROM country_admin_level cal
USING luxembourg lu
WHERE cal.country_id = lu.id;

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
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
    lu.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM luxembourg lu
CROSS JOIN seed s;

WITH luxembourg AS (
    SELECT id
    FROM country
    WHERE iso_code = 'LU'
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM luxembourg lu
JOIN country_admin_level parent
    ON parent.country_id = lu.id
   AND parent.code = 'canton'
WHERE child.country_id = lu.id
  AND child.code = 'municipality';

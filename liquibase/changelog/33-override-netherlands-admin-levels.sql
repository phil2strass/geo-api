--liquibase formatted sql

--changeset codex:33-override-netherlands-admin-levels dbms:postgresql
--comment Replace the inferred Netherlands hierarchy with curated official provinces and municipalities.

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
)
DELETE FROM country_admin_level cal
USING netherlands nl
WHERE cal.country_id = nl.id;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'province', 'Province', 'province'),
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
    nl.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM netherlands nl
CROSS JOIN seed s;

WITH netherlands AS (
    SELECT id
    FROM country
    WHERE iso_code = 'NL'
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM netherlands nl
JOIN country_admin_level parent
    ON parent.country_id = nl.id
   AND parent.code = 'province'
WHERE child.country_id = nl.id
  AND child.code = 'municipality';

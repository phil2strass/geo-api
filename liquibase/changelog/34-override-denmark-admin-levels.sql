--liquibase formatted sql

--changeset codex:34-override-denmark-admin-levels dbms:postgresql
--comment Replace the inferred Denmark hierarchy with curated official regions, municipalities and the Christianso state-managed area.

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
)
DELETE FROM country_admin_level cal
USING denmark dk
WHERE cal.country_id = dk.id;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'region', 'Region', 'region'),
        (2, 'municipality', 'Municipality', 'municipality'),
        (3, 'state_managed_area', 'State Managed Area', 'region')
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
    dk.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM denmark dk
CROSS JOIN seed s;

WITH denmark AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DK'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('municipality', 'region'),
        ('state_managed_area', 'region')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM denmark dk
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = dk.id
   AND parent.code = ps.parent_code
WHERE child.country_id = dk.id
  AND child.code = ps.child_code;

--liquibase formatted sql

--changeset codex:36-override-austria-admin-levels dbms:postgresql
--comment Replace the inferred Austria hierarchy with curated official states, districts and municipalities.

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
)
DELETE FROM country_admin_level cal
USING austria at
WHERE cal.country_id = at.id;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'state', 'State', 'region'),
        (2, 'district', 'District', 'district'),
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
    at.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM austria at
CROSS JOIN seed s;

WITH austria AS (
    SELECT id
    FROM country
    WHERE iso_code = 'AT'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('district', 'state'),
        ('municipality', 'district')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM austria at
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = at.id
   AND parent.code = ps.parent_code
WHERE child.country_id = at.id
  AND child.code = ps.child_code;

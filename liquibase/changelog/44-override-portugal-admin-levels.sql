--liquibase formatted sql

--changeset codex:44-override-portugal-admin-levels dbms:postgresql
--comment Replace the inferred Portugal hierarchy with curated district-or-island, municipality and civil parish levels.

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
)
DELETE FROM country_admin_level cal
USING portugal pt
WHERE cal.country_id = pt.id;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'district_or_island', 'District or Island', 'region'),
        (2, 'municipality', 'Municipality', 'municipality'),
        (3, 'civil_parish', 'Civil Parish', 'region')
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
    pt.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM portugal pt
CROSS JOIN seed s;

WITH portugal AS (
    SELECT id
    FROM country
    WHERE iso_code = 'PT'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('municipality', 'district_or_island'),
        ('civil_parish', 'municipality')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM portugal pt
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = pt.id
   AND parent.code = ps.parent_code
WHERE child.country_id = pt.id
  AND child.code = ps.child_code;

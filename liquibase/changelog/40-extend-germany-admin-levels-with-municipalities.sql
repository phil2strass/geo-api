--liquibase formatted sql

--changeset codex:40-extend-germany-admin-levels-with-municipalities dbms:postgresql
--comment Extend the curated Germany hierarchy with the municipality level.

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
)
DELETE FROM country_admin_level cal
USING germany g
WHERE cal.country_id = g.id;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'state', 'Land', NULL),
        (2, 'government_region', 'Regierungsbezirk', 'region'),
        (3, 'kreis', 'Kreis', 'region'),
        (4, 'municipality', 'Gemeinde', 'municipality')
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
    g.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM germany g
CROSS JOIN seed s;

WITH germany AS (
    SELECT id
    FROM country
    WHERE iso_code = 'DE'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('government_region', 'state'),
        ('kreis', 'state'),
        ('municipality', 'kreis')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM germany g
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = g.id
   AND parent.code = ps.parent_code
WHERE child.country_id = g.id
  AND child.code = ps.child_code;

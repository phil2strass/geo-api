--liquibase formatted sql

--changeset codex:42-override-ireland-admin-levels dbms:postgresql
--comment Replace the inferred Ireland hierarchy with a curated county layer backed by county-named territory items.

WITH ireland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IE'
)
DELETE FROM country_admin_level cal
USING ireland i
WHERE cal.country_id = i.id;

WITH ireland AS (
    SELECT id
    FROM country
    WHERE iso_code = 'IE'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'county', 'County', 'region')
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
    i.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM ireland i
CROSS JOIN seed s;

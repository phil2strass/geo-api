--liquibase formatted sql

--changeset codex:27-override-germany-admin-levels dbms:postgresql
--comment Replace the inferred Germany hierarchy with the curated official state level.

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
    1,
    'state',
    'Land',
    NULL,
    NULL,
    TRUE
FROM germany g;

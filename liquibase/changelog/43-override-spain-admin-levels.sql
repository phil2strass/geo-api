--liquibase formatted sql

--changeset codex:43-override-spain-admin-levels dbms:postgresql
--comment Replace the inferred Spain hierarchy with curated autonomous community/city, province and municipality levels.

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
)
DELETE FROM country_admin_level cal
USING spain es
WHERE cal.country_id = es.id;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'autonomous_community_or_city', 'Autonomous Community or City', 'region'),
        (2, 'province', 'Province', 'province'),
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
    es.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM spain es
CROSS JOIN seed s;

WITH spain AS (
    SELECT id
    FROM country
    WHERE iso_code = 'ES'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('province', 'autonomous_community_or_city'),
        ('municipality', 'province')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM spain es
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = es.id
   AND parent.code = ps.parent_code
WHERE child.country_id = es.id
  AND child.code = ps.child_code;

--liquibase formatted sql

--changeset codex:31-override-belgium-admin-levels dbms:postgresql
--comment Replace the inferred Belgium hierarchy with curated official regions, provinces, arrondissements and municipalities.

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
)
DELETE FROM country_admin_level cal
USING belgium b
WHERE cal.country_id = b.id;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'region', 'Region', 'region'),
        (2, 'province', 'Province', 'province'),
        (3, 'arrondissement', 'Arrondissement', 'region'),
        (4, 'municipality', 'Municipality', 'municipality')
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
    b.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM belgium b
CROSS JOIN seed s;

WITH belgium AS (
    SELECT id
    FROM country
    WHERE iso_code = 'BE'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('province', 'region'),
        ('arrondissement', 'province'),
        ('municipality', 'arrondissement')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM belgium b
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = b.id
   AND parent.code = ps.parent_code
WHERE child.country_id = b.id
  AND child.code = ps.child_code;

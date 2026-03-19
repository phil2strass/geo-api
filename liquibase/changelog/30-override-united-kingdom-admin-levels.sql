--liquibase formatted sql

--changeset codex:30-override-united-kingdom-admin-levels dbms:postgresql
--comment Replace the inferred United Kingdom hierarchy with curated ONS constituent countries and local authority districts.

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
)
DELETE FROM country_admin_level cal
USING united_kingdom uk
WHERE cal.country_id = uk.id;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
seed(level_number, code, label, default_territory_type_code) AS (
    VALUES
        (1, 'constituent_country', 'Constituent Country', 'region'),
        (2, 'local_authority_district', 'Local Authority District', 'district')
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
    uk.id,
    s.level_number,
    s.code,
    s.label,
    s.default_territory_type_code,
    NULL,
    TRUE
FROM united_kingdom uk
CROSS JOIN seed s;

WITH united_kingdom AS (
    SELECT id
    FROM country
    WHERE iso_code = 'GB'
),
parent_seed(child_code, parent_code) AS (
    VALUES
        ('local_authority_district', 'constituent_country')
)
UPDATE country_admin_level child
SET parent_level_id = parent.id
FROM united_kingdom uk
JOIN parent_seed ps ON TRUE
JOIN country_admin_level parent
    ON parent.country_id = uk.id
   AND parent.code = ps.parent_code
WHERE child.country_id = uk.id
  AND child.code = ps.child_code;

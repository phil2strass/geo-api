--liquibase formatted sql

--changeset codex:38-fix-france-wolxheim-territory dbms:postgresql
--comment Correct the Wolxheim territory row so it can be used by the French administrative hierarchy.

WITH france AS (
    SELECT id
    FROM country
    WHERE iso_code = 'FR'
),
bas_rhin AS (
    SELECT t.id
    FROM territory t
    JOIN country c ON c.id = t.country_id
    WHERE c.iso_code = 'FR'
      AND t.wikidata_id = 'Q12717'
)
UPDATE territory t
SET
    country_id = france.id,
    parent_id = bas_rhin.id
FROM france, bas_rhin
WHERE t.wikidata_id = 'Q21533'
  AND (
      t.country_id IS DISTINCT FROM france.id
      OR t.parent_id IS DISTINCT FROM bas_rhin.id
  );

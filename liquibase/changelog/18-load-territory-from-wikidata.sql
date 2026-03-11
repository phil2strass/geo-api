--liquibase formatted sql
--changeset codex:18-load-territory-from-wikidata dbms:postgresql
--comment Load territory data from Wikidata (P17/P31/P279/P131/P625) with mapped territory types.

WITH data (wikidata_id, name, type, country_iso, parent_wikidata_id, latitude, longitude) AS (
    VALUES
        ('Q234963', 'Catalan countries', 'cultural_region', 'AD', NULL, 40.567000, 0.650000),
        ('Q64364520', 'Historic Ensemble of Santa Coloma', 'region', 'AD', 'Q1863', 42.490400, 1.497000),
        ('Q2749444', 'South-West Europe', 'region', 'AD', NULL, NULL, NULL),
        ('Q27449', 'Southern Europe', 'region', 'AD', NULL, 41.093498, 15.017008)
), upsert AS (
    INSERT INTO territory (wikidata_id, name, type, country_id, parent_id, latitude, longitude)
    SELECT
        d.wikidata_id,
        d.name,
        d.type,
        c.id,
        NULL,
        d.latitude,
        d.longitude
    FROM data d
    JOIN country c ON c.iso_code = d.country_iso
    ON CONFLICT (wikidata_id) DO UPDATE
    SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        country_id = EXCLUDED.country_id,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude
)
UPDATE territory t
SET parent_id = p.id
FROM data d
JOIN territory p ON p.wikidata_id = d.parent_wikidata_id
WHERE t.wikidata_id = d.wikidata_id
  AND d.parent_wikidata_id IS NOT NULL
  AND t.parent_id IS DISTINCT FROM p.id;

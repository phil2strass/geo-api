--liquibase formatted sql
--changeset codex:19-create-country-translation-table dbms:postgresql
--comment Store country names translated by language.

CREATE TABLE IF NOT EXISTS country_translation (
 country_id BIGINT NOT NULL,
 language_id BIGINT NOT NULL,
 common_name VARCHAR(200) NOT NULL,
 official_name VARCHAR(260),
 source VARCHAR(120) NOT NULL DEFAULT 'seed.fallback.country_defaults',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT pk_country_translation PRIMARY KEY (country_id, language_id),
 CONSTRAINT fk_country_translation_country
 FOREIGN KEY (country_id) REFERENCES country(id) ON DELETE CASCADE,
 CONSTRAINT fk_country_translation_language
 FOREIGN KEY (language_id) REFERENCES language(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_country_translation_language_id
 ON country_translation(language_id);

CREATE INDEX IF NOT EXISTS ix_country_translation_common_name
 ON country_translation(common_name);

COMMENT ON TABLE country_translation IS
'Country translated names by language. source=fallback means not a real translation yet.';

--changeset codex:19-seed-country-translation-fallback dbms:postgresql
--comment Seed one row per (country, language) with default country names as fallback values.

INSERT INTO country_translation (country_id, language_id, common_name, official_name, source)
SELECT
 c.id,
 l.id,
 c.name,
 c.official_name,
 'seed.fallback.country_defaults'
FROM country c
CROSS JOIN language l
ON CONFLICT (country_id, language_id) DO NOTHING;

--changeset codex:19-create-country-translation-view dbms:postgresql
--comment Convenience view to query translations with language and country codes.

CREATE OR REPLACE VIEW v_country_translation AS
SELECT
 ct.country_id,
 c.iso_code AS country_iso2,
 c.iso3_code AS country_iso3,
 c.name AS country_default_name,
 ct.language_id,
 l.iso639_1,
 l.iso639_2t,
 l.iso639_3,
 l.english_name AS language_name_en,
 ct.common_name,
 ct.official_name,
 ct.source
FROM country_translation ct
JOIN country c ON c.id = ct.country_id
JOIN language l ON l.id = ct.language_id;

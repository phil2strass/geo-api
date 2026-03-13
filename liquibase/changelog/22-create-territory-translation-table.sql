--liquibase formatted sql
--changeset codex:21-create-territory-translation-table dbms:postgresql
--comment Store territory names translated by language.

CREATE TABLE IF NOT EXISTS territory_translation (
 territory_id BIGINT NOT NULL,
 language_id BIGINT NOT NULL,
 name VARCHAR(200) NOT NULL,
 source VARCHAR(120) NOT NULL DEFAULT 'seed.fallback.territory_defaults',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT pk_territory_translation PRIMARY KEY (territory_id, language_id),
 CONSTRAINT fk_territory_translation_territory
 FOREIGN KEY (territory_id) REFERENCES territory(id) ON DELETE CASCADE,
 CONSTRAINT fk_territory_translation_language
 FOREIGN KEY (language_id) REFERENCES language(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_territory_translation_language_id
 ON territory_translation(language_id);

CREATE INDEX IF NOT EXISTS ix_territory_translation_name
 ON territory_translation(name);

COMMENT ON TABLE territory_translation IS
'Territory translated names by language. source=fallback means not a real translation yet.';

--changeset codex:21-create-territory-translation-view dbms:postgresql
--comment Convenience view to query translations with language and territory metadata.

CREATE OR REPLACE VIEW v_territory_translation AS
SELECT
 tt.territory_id,
 t.wikidata_id AS territory_wikidata_id,
 t.name AS territory_default_name,
 t.type AS territory_type,
 c.iso_code AS country_iso2,
 c.iso3_code AS country_iso3,
 tt.language_id,
 l.iso639_1,
 l.iso639_2t,
 l.iso639_3,
 l.english_name AS language_name_en,
 tt.name,
 tt.source
FROM territory_translation tt
JOIN territory t ON t.id = tt.territory_id
JOIN country c ON c.id = t.country_id
JOIN language l ON l.id = tt.language_id;

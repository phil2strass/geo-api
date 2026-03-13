--liquibase formatted sql
--changeset codex:20-create-language-translation-table dbms:postgresql
--comment Store language names translated by language.

CREATE TABLE IF NOT EXISTS language_translation (
 language_id BIGINT NOT NULL,
 translation_language_id BIGINT NOT NULL,
 name VARCHAR(200) NOT NULL,
 source VARCHAR(120) NOT NULL DEFAULT 'wikidata.truthy.rdfslabel',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT pk_language_translation PRIMARY KEY (language_id, translation_language_id),
 CONSTRAINT fk_language_translation_language
 FOREIGN KEY (language_id) REFERENCES language(id) ON DELETE CASCADE,
 CONSTRAINT fk_language_translation_translation_language
 FOREIGN KEY (translation_language_id) REFERENCES language(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS ix_language_translation_translation_language_id
 ON language_translation(translation_language_id);

CREATE INDEX IF NOT EXISTS ix_language_translation_name
 ON language_translation(name);

COMMENT ON TABLE language_translation IS
'Language translated names by language.';

--changeset codex:20-create-language-translation-view dbms:postgresql
--comment Convenience view to query language translations with source and target language codes.

CREATE OR REPLACE VIEW v_language_translation AS
SELECT
 lt.language_id,
 src.iso639_1 AS language_iso639_1,
 src.iso639_2t AS language_iso639_2t,
 src.iso639_3 AS language_iso639_3,
 src.english_name AS language_name_en,
 lt.translation_language_id,
 trg.iso639_1 AS translation_iso639_1,
 trg.iso639_2t AS translation_iso639_2t,
 trg.iso639_3 AS translation_iso639_3,
 trg.english_name AS translation_language_name_en,
 lt.name,
 lt.source
FROM language_translation lt
JOIN language src ON src.id = lt.language_id
JOIN language trg ON trg.id = lt.translation_language_id;

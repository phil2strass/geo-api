--liquibase formatted sql
--changeset codex:7-fix-country-languages-ascii dbms:postgresql
--comment Normalize country.languages values to ASCII to avoid mojibake.

UPDATE country c
SET languages = (
    SELECT jsonb_object_agg(e.key, regexp_replace(e.value, '[^ -~]', '', 'g'))
    FROM jsonb_each_text(c.languages) AS e(key, value)
)
WHERE c.languages IS NOT NULL
  AND jsonb_typeof(c.languages) = 'object';

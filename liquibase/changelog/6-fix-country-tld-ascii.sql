--liquibase formatted sql
--changeset codex:6-fix-country-tld-ascii dbms:postgresql
--comment Keep only ASCII TLD values to avoid mojibake from non-ASCII IDN entries.

UPDATE country c
SET tld = COALESCE(
    (
        SELECT jsonb_agg(to_jsonb(e.elem))
        FROM jsonb_array_elements_text(c.tld) AS e(elem)
        WHERE octet_length(e.elem) = char_length(e.elem)
    ),
    '[]'::jsonb
)
WHERE c.tld IS NOT NULL
  AND jsonb_typeof(c.tld) = 'array';

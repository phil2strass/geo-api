--liquibase formatted sql
--changeset codex:8-fix-country-currencies-ascii dbms:postgresql
--comment Normalize country.currencies values to ASCII and null out unreadable symbols.

UPDATE country c
SET currencies = (
    SELECT jsonb_object_agg(
        e.key,
        jsonb_build_object(
            'name', regexp_replace(COALESCE(e.value->>'name', ''), '[^ -~]', '', 'g'),
            'symbol', NULLIF(regexp_replace(COALESCE(e.value->>'symbol', ''), '[^ -~]', '', 'g'), '')
        )
    )
    FROM jsonb_each(c.currencies) AS e(key, value)
)
WHERE c.currencies IS NOT NULL
  AND jsonb_typeof(c.currencies) = 'object';

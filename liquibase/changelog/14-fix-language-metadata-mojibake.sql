--liquibase formatted sql
--changeset codex:14-fix-language-metadata-mojibake dbms:postgresql
--comment Remove mojibake/replacement chars from language metadata and keep safe fallbacks.

-- Clean scalar text fields.
UPDATE language
SET
    english_name = NULLIF(trim(regexp_replace(english_name, '[^ -~]', '', 'g')), ''),
    native_name = NULLIF(trim(regexp_replace(native_name, '[^ -~]', '', 'g')), ''),
    language_family = NULLIF(trim(regexp_replace(language_family, '[^ -~]', '', 'g')), ''),
    notes = NULLIF(trim(regexp_replace(notes, '[^ -~]', '', 'g')), '')
WHERE
    english_name IS NOT NULL
    OR native_name IS NOT NULL
    OR language_family IS NOT NULL
    OR notes IS NOT NULL;

-- Ensure english_name is always present after cleanup.
UPDATE language
SET english_name = iso639_3
WHERE english_name IS NULL OR english_name = '';

-- Clean writing systems JSON array values to ASCII.
UPDATE language l
SET writing_systems = cleaned.ws
FROM (
    SELECT
        id,
        CASE
            WHEN COUNT(*) FILTER (WHERE cleaned_value <> '') = 0 THEN NULL::jsonb
            ELSE jsonb_agg(cleaned_value)
        END AS ws
    FROM (
        SELECT
            l2.id,
            regexp_replace(value, '[^ -~]', '', 'g') AS cleaned_value
        FROM language l2
        CROSS JOIN LATERAL jsonb_array_elements_text(l2.writing_systems) AS e(value)
        WHERE l2.writing_systems IS NOT NULL
          AND jsonb_typeof(l2.writing_systems) = 'array'
    ) s
    GROUP BY id
) cleaned
WHERE l.id = cleaned.id;

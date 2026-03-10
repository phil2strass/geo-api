--liquibase formatted sql
--changeset codex:5-fix-country-flag-emoji dbms:postgresql
--comment Recompute country flag emoji from ISO code to avoid file-encoding issues.

UPDATE country
SET flag_emoji =
    chr(127397 + ascii(substr(iso_code, 1, 1))) ||
    chr(127397 + ascii(substr(iso_code, 2, 1)))
WHERE iso_code ~ '^[A-Z]{2}$';

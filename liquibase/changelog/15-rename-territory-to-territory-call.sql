--liquibase formatted sql
--changeset codex:15-rename-territory-to-territory-call dbms:postgresql
--comment Rename territory table to territory_call and align related object names.

ALTER TABLE IF EXISTS public.territory RENAME TO territory_call;
ALTER INDEX IF EXISTS public.ix_territory_country_id RENAME TO ix_territory_call_country_id;
ALTER TABLE public.territory_call RENAME CONSTRAINT pk_territory TO pk_territory_call;
ALTER SEQUENCE IF EXISTS public.territory_id_seq RENAME TO territory_call_id_seq;

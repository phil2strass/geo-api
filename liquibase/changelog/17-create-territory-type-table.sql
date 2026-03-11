--liquibase formatted sql
--changeset codex:17-create-territory-type-table dbms:postgresql
--comment Normalize territory types and Wikidata label mapping.

CREATE TABLE IF NOT EXISTS territory_type (
    code VARCHAR(32) PRIMARY KEY,
    label VARCHAR(120) NOT NULL,
    description TEXT
);

INSERT INTO territory_type (code, label, description)
VALUES
    ('state', 'State', 'Federal state or equivalent first-level state entity.'),
    ('province', 'Province', 'Province-level administrative division.'),
    ('region', 'Region', 'Administrative region.'),
    ('department', 'Department', 'Department-level administrative division.'),
    ('county', 'County', 'County-level administrative division.'),
    ('district', 'District', 'District-level administrative division.'),
    ('municipality', 'Municipality', 'Municipality or commune.'),
    ('autonomous_region', 'Autonomous Region', 'Autonomous region with specific self-governance.'),
    ('overseas_region', 'Overseas Region/Territory', 'Overseas department or overseas territory.'),
    ('historical_region', 'Historical Region', 'Historical region, no longer active as standard admin unit.'),
    ('cultural_region', 'Cultural Region', 'Region defined mainly by cultural features.')
ON CONFLICT (code) DO UPDATE
SET
    label = EXCLUDED.label,
    description = EXCLUDED.description;

CREATE TABLE IF NOT EXISTS territory_type_wikidata_map (
    wikidata_type_label VARCHAR(120) PRIMARY KEY,
    territory_type_code VARCHAR(32) NOT NULL REFERENCES territory_type(code)
);

INSERT INTO territory_type_wikidata_map (wikidata_type_label, territory_type_code)
VALUES
    ('federal state', 'state'),
    ('province', 'province'),
    ('region', 'region'),
    ('department', 'department'),
    ('county', 'county'),
    ('district', 'district'),
    ('municipality', 'municipality'),
    ('autonomous region', 'autonomous_region'),
    ('overseas department', 'overseas_region'),
    ('overseas territory', 'overseas_region'),
    ('historical region', 'historical_region'),
    ('cultural region', 'cultural_region')
ON CONFLICT (wikidata_type_label) DO UPDATE
SET territory_type_code = EXCLUDED.territory_type_code;

ALTER TABLE territory
ADD CONSTRAINT fk_territory_type
FOREIGN KEY (type) REFERENCES territory_type(code);

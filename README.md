# geo-api

API Python pour lire les donnees geo, avec gestion de deux bases PostgreSQL :
- `geo2` (donnees pays/geo)
- `glottolog` (dump linguistique)

## Architecture proposee

- `FastAPI` pour l'exposition HTTP.
- `SQLAlchemy` pour l'acces base.
- Separation simple en couches :
  - `api` (routes)
  - `services` (logique metier)
  - `repositories` (acces donnees)
  - `models/schemas` (modele DB + contrats API)
- `PostgreSQL` avec deux bases logiques (`geo2`, `glottolog`).

## Structure du projet

```text
app/
  api/
    v1/
      endpoints/
  core/
  db/
  models/
  repositories/
  schemas/
  services/
data/
  glottolog.sql
docker/
  postgres/
    initdb/
liquibase/
  changelog/
docker-compose.yml
```

## Prerequis

- Docker + Docker Compose
- (Optionnel) Python 3.12+ pour lancer l'API localement hors Docker

## Variables d'environnement

Copier `.env.example` vers `.env` et adapter si besoin.

## Demarrage rapide

1. Demarrer la base :

```bash
docker compose up -d db
```

2. Appliquer les migrations Liquibase (base `geo2`) :

```cmd
docker run --rm -v "%cd%\liquibase:/liquibase" -w /liquibase liquibase/liquibase:4.31 ^
  --classpath=/liquibase/lib/postgresql.jar ^
  --driver=org.postgresql.Driver ^
  --url=jdbc:postgresql://host.docker.internal:55432/geo2 ^
  --username=geo ^
  --password=geo ^
  --changeLogFile=changelog/db.changelog-master.yaml ^
  update
```

3. Demarrer l'API :

```bash
docker compose up --build api
```

API dispo sur `http://localhost:8000`.

## Endpoints

- `GET /health`
- `GET /api/v1/geos?country_code=FR&limit=100`

## Execution locale (sans Docker pour l'API)

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Dans ce cas :
- `DATABASE_URL` pointe vers `geo2`
- `GLOTTOLOG_DATABASE_URL` pointe vers `glottolog`

## Liquibase

Liquibase est utilise uniquement pour la base `geo2` :

Sans installation locale de Liquibase (recommande) :

```cmd
docker run --rm -v "%cd%\liquibase:/liquibase" -w /liquibase liquibase/liquibase:4.31 ^
  --classpath=/liquibase/lib/postgresql.jar ^
  --driver=org.postgresql.Driver ^
  --url=jdbc:postgresql://host.docker.internal:55432/geo2 ^
  --username=geo ^
  --password=geo ^
  --changeLogFile=changelog/db.changelog-master.yaml ^
  update
```

Avec Liquibase installe localement (Linux / Git Bash / WSL) :

```bash
./liquibase/run-migrations.sh geo
bash .\liquibase\run-migrations.sh geo

```

Fichier de config :
- `liquibase/liquibase.geo.properties`

## Import initial Glottolog

Le fichier `data/glottolog.sql` est un dump `pg_dump` avec `COPY ... FROM stdin` (format psql), non executable via JDBC Liquibase.

Importer le dump avec `psql` :

```bash
psql postgresql://geo:geo@localhost:55432/glottolog -f data/glottolog.sql
```

## Import Wikidata des territoires

1. Generer le SQL d'upsert territories depuis Wikidata (API WDQS) :

```bash
python3 scripts/generate_territory_wikidata_sql.py
```

Alternative sans API (recommande en cas de timeouts WDQS), a partir d'un dump local :

```bash
python3 scripts/generate_territory_wikidata_sql_from_dump.py \
  --dump-file /chemin/vers/latest-all.json.bz2
```

Ce mode fait un parcours exhaustif du dump (sans perte de donnees), mais peut prendre plusieurs heures.

Alternative recommandee WDQS (dump SPARQL "truthy", plus compact) :

```bash
python3 scripts/generate_territory_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2
```

Test rapide sur un pays :

```bash
python3 scripts/generate_territory_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2 \
  --only-iso AF
```

Pour tester rapidement un pays :

```bash
python3 scripts/generate_territory_wikidata_sql_from_dump.py \
  --dump-file /chemin/vers/latest-all.json.bz2 \
  --only-iso AF
```

2. Appliquer les migrations Liquibase puis lancer le programme Python dedie a la migration `18` :

`18-load-territory-from-wikidata.sql` n'est plus execute par Liquibase. `./liquibase/run-migrations.sh geo` applique uniquement le changelog schema/reference. La migration de donnees `18` se lance ensuite separement via un programme Python.

```bash
./liquibase/run-migrations.sh geo
```

Pour lancer seulement la migration `18` apres generation du fichier source :

```bash
python3 scripts/import_territory_wikidata.py
```

`territory` reste le gazetteer large importe depuis Wikidata. La hierarchie administrative propre est desormais separee dans :
- `country_admin_level` : niveaux admin par pays
- `admin_territory` : unites admin propres, avec `display_name` et `admin_code`
- `city` : projection metier des villes du monde, reliee a Wikidata et optionnellement a `territory`
- `admin_territory_city` : liens explicites entre unite administrative et ville (`seat`, `coextensive`, `largest_city`)

La migration `26-load-country-admin-levels.sql` seed `country_admin_level` pour tous les pays a partir du snapshot normalise `18-load-territory-from-wikidata.sql` (France conserve son override manuel defini en migration `25`).
Pour regenerer ce seed :

```bash
python3 scripts/generate_country_admin_level_sql.py
```

Le sync administratif reste separe de la migration `18` et peuple pour l'instant :
- la France sur les niveaux officiels `region`, `department`, `arrondissement`, `canton` et `commune`
- l'Allemagne sur les niveaux officiels `state`, `government_region` et `kreis`
- le Royaume-Uni sur les niveaux officiels `constituent_country` et `local_authority_district`
- la Belgique sur les niveaux officiels `region`, `province`, `arrondissement` et `municipality`
- le Luxembourg sur les niveaux officiels `canton` et `municipality`
- la Suisse sur les niveaux officiels `canton` et `municipality`
- l'Autriche sur les niveaux officiels `state`, `district` et `municipality`
- le Danemark sur les niveaux officiels `region`, `municipality` et `state_managed_area`
- les Pays-Bas sur les niveaux officiels `province` et `municipality`
- l'Italie sur les niveaux officiels `region`, `province_or_equivalent` et `municipality`

Le seed officiel des Kreise allemands est versionne dans `scripts/data/de_kreise_seed.tsv`.
Pour le regenerer depuis la couche officielle BKG `vg1000_krs` et le mapping Wikidata `P440` :

```bash
python3 scripts/generate_de_kreise_seed.py
```

Le seed administratif francais est versionne dans `scripts/data/fr_admin_seed.tsv`.
Pour le regenerer depuis le COG Insee 2026 et les codes Wikidata :

```bash
python3 scripts/generate_fr_admin_seed.py
```

Pour peupler `city` et `admin_territory_city` a partir des unites locales deja chargees
dans `admin_territory` (`FR commune`, `BE/LU/CH/AT/NL/DK/IT municipality`), avec
enrichissement Wikidata :

```bash
LIQUIBASE_DB_HOST=localhost LIQUIBASE_DB_PORT=5432 LIQUIBASE_DB_NAME=geo2 LIQUIBASE_DB_USER=geo LIQUIBASE_DB_PASSWORD=geo \
python3 scripts/sync_admin_territory_city.py
```

Pour limiter le sync a certains pays :

```bash
LIQUIBASE_DB_HOST=localhost LIQUIBASE_DB_PORT=5432 LIQUIBASE_DB_NAME=geo2 LIQUIBASE_DB_USER=geo LIQUIBASE_DB_PASSWORD=geo \
python3 scripts/sync_admin_territory_city.py --country FR --country BE
```

Le seed officiel des local authority districts du Royaume-Uni est versionne dans
`scripts/data/gb_local_authority_district_seed.tsv`.
Pour le regenerer depuis les jeux ONS 2025 et le mapping Wikidata `P836` :

```bash
python3 scripts/generate_gb_local_authority_district_seed.py
```

Le seed administratif officiel de la Belgique est versionne dans
`scripts/data/be_admin_seed.tsv`.
Pour le regenerer depuis le REFNIS 2025 officiel de Statbel et le mapping Wikidata `P1567` :

```bash
python3 scripts/generate_be_admin_seed.py
```

Le seed administratif officiel du Luxembourg est versionne dans
`scripts/data/lu_admin_seed.tsv`.
Pour le regenerer depuis le CSV officiel ACT `commune-canton-district-circonscription-arrondissements`
et le snapshot `18-load-territory-from-wikidata.sql` :

```bash
python3 scripts/generate_lu_admin_seed.py
```

Le seed administratif officiel de la Suisse est versionne dans
`scripts/data/ch_admin_seed.tsv`.
Pour le regenerer depuis l'API officielle BFS `communes/levels` au `01.01.2026`
et le mapping Wikidata `P771` :

```bash
python3 scripts/generate_ch_admin_seed.py
```

Le seed administratif officiel de l'Autriche est versionne dans
`scripts/data/at_admin_seed.tsv`.
Pour le regenerer depuis les WFS officiels Statistik Austria `GEM_20260101` et
`POLBEZ_20260101` et le mapping Wikidata `P964` :

```bash
python3 scripts/generate_at_admin_seed.py
```

Le seed administratif officiel du Danemark est versionne dans
`scripts/data/dk_admin_seed.tsv`.
Pour le regenerer depuis le CSV officiel DST `Regioner, landsdele og kommuner, v1:2007-`
et le mapping Wikidata `P1168` :

```bash
python3 scripts/generate_dk_admin_seed.py
```

Le seed administratif officiel des Pays-Bas est versionne dans
`scripts/data/nl_admin_seed.tsv`.
Pour le regenerer depuis le classeur officiel CBS `Gemeenten alfabetisch 2026`,
la note CBS sur les codes `9001/9002/9003` de Caribisch Nederland et Wikidata `P382` :

```bash
python3 scripts/generate_nl_admin_seed.py
```

Le seed administratif officiel de l'Italie est versionne dans
`scripts/data/it_admin_seed.tsv`.
Pour le regenerer depuis le classeur officiel ISTAT `Elenco comuni italiani`,
le mapping Wikidata `P635` et le snapshot `18-load-territory-from-wikidata.sql` :

```bash
python3 scripts/generate_it_admin_seed.py
```

Pour lancer seulement ce sync :

```bash
./scripts/sync_admin_territory.sh
```

Exemple pour lister les departements francais avec leur code :

```sql
SELECT admin_code, display_name, parent_display_name
FROM v_admin_territory
WHERE country_iso2 = 'FR'
  AND admin_level_code = 'department'
ORDER BY admin_code;
```

```cmd
docker run --rm -v "%cd%\liquibase:/liquibase" -w /liquibase liquibase/liquibase:4.31 ^
  --classpath=/liquibase/lib/postgresql.jar ^
  --driver=org.postgresql.Driver ^
  --url=jdbc:postgresql://host.docker.internal:55432/geo2 ^
  --username=geo ^
  --password=geo ^
  --changeLogFile=changelog/db.changelog-master.yaml ^
  update
```

## Import Wikidata des traductions de pays

Generer la migration SQL des traductions pays depuis le dump WDQS truthy :

```bash
python3 scripts/generate_country_translation_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2
```

Test rapide sur un pays / quelques langues :

```bash
python3 scripts/generate_country_translation_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2 \
  --only-iso FR \
  --only-lang fr,en,de
```

Le script ecrit `liquibase/changelog/21-load-country-translations-from-wikidata.sql`.
Ensuite, ajouter ce fichier dans `liquibase/changelog/db.changelog-master.yaml`, puis appliquer `liquibase update`.

## Import Wikidata des traductions de langues

Creer d'abord la table `language_translation` via Liquibase avec `changelog/20-create-language-translation-table.sql`.

Generer ensuite la migration SQL des traductions de langues depuis le dump WDQS truthy :

```bash
python3 scripts/generate_language_translation_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2
```

Test rapide sur quelques langues / quelques traductions :

```bash
python3 scripts/generate_language_translation_wikidata_sql_from_truthy_nt.py \
  --dump-file /chemin/vers/latest-truthy.nt.bz2 \
  --only-iso6393 fra,eng,deu \
  --only-lang fr,en,de
```

Le script ecrit `liquibase/changelog/23-load-language-translations-from-wikidata.sql`.
Ensuite, ajouter ce fichier dans `liquibase/changelog/db.changelog-master.yaml`, puis appliquer `liquibase update`.

# glotolog
psql "postgresql://geo:geo@localhost:5432/glottolog" -v ON_ERROR_STOP=1 -f data/glottolog.sql

Si la base existe déjà, réimport propre:
dropdb -h localhost -p 5432 -U geo --if-exists glottolog
createdb -h localhost -p 5432 -U geo glottolog
psql "postgresql://geo:geo@localhost:5432/glottolog" -v ON_ERROR_STOP=1 -f data/glottolog.sql

chmod +x scripts/osm/country/create_osm_pbf.sh
./scripts/osm/country/create_osm_pbf.sh \
--world-dem /chemin/vers/world_30m.vrt \
--country-pbf-dir /srv/pgdata/osm/pays \
--output-dir /srv/pgdata/osm/dem/tif

python3 scripts/generate_territory_wikidata_sql_from_truthy_nt.py --dump-file data/latest-truthy.nt.1.bz2

PGPASSWORD=geo psql -h localhost -p 5432 -U geo -d geo2 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# database
./liquibase/run-migrations.sh geo

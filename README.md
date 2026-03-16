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

2. Appliquer les migrations Liquibase puis lancer l'import des territoires :

`18-load-territory-from-wikidata.sql` n'est plus execute par Liquibase. `./liquibase/run-migrations.sh geo` applique d'abord le changelog schema/reference, puis recharge ce fichier SQL source en flux vers PostgreSQL sans fichiers intermediaires.

```bash
./liquibase/run-migrations.sh geo
```

Pour lancer seulement l'import SQL des territoires apres generation du fichier source :

```bash
./scripts/import_territory_wikidata.sh
```

`territory` reste le gazetteer large importe depuis Wikidata. La hierarchie administrative propre est desormais separee dans :
- `country_admin_level` : niveaux admin par pays
- `admin_territory` : unites admin propres, avec `display_name` et `admin_code`

Le sync post-import peuple pour l'instant la France sur les niveaux `region` et `department`.
Pour relancer seulement ce sync :

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

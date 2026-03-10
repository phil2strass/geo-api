# geo-api

API Python pour lire les donnnees de la table `geo`.

## Architecture proposee

- `FastAPI` pour l'exposition HTTP.
- `SQLAlchemy` pour l'acces base.
- Separation simple en couches :
  - `api` (routes)
  - `services` (logique metier)
  - `repositories` (acces donnees)
  - `models/schemas` (modele DB + contrats API)
- `PostgreSQL` comme base cible (modifiable).

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
liquibase/
  changelog/
  data/
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

2. Demarrer l'API :

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

Dans ce cas, la variable `DATABASE_URL` doit pointer vers la base PostgreSQL.

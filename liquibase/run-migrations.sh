#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
  echo "Usage: $0 [geo]"
}

TARGET="${1:-geo}"
LIQUIBASE_DB_HOST="${LIQUIBASE_DB_HOST:-localhost}"
LIQUIBASE_DB_PORT="${LIQUIBASE_DB_PORT:-5432}"
LIQUIBASE_DB_NAME="${LIQUIBASE_DB_NAME:-geo2}"
LIQUIBASE_DB_USER="${LIQUIBASE_DB_USER:-geo}"
LIQUIBASE_DB_PASSWORD="${LIQUIBASE_DB_PASSWORD:-geo}"

run_geo() {
  echo "Running Liquibase for geo2..."
  liquibase \
    --classpath=lib/postgresql.jar \
    --driver=org.postgresql.Driver \
    --url="jdbc:postgresql://${LIQUIBASE_DB_HOST}:${LIQUIBASE_DB_PORT}/${LIQUIBASE_DB_NAME}" \
    --username="${LIQUIBASE_DB_USER}" \
    --password="${LIQUIBASE_DB_PASSWORD}" \
    --changeLogFile=changelog/db.changelog-master.yaml \
    update
}

case "$TARGET" in
  geo)
    run_geo
    ;;
  *)
    usage
    exit 1
    ;;
esac

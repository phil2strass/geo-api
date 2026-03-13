#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
  echo "Usage: $0 [geo]"
}

TARGET="${1:-geo}"
LIQUIBASE_DB_HOST="${LIQUIBASE_DB_HOST:-localhost}"
LIQUIBASE_DB_PORT="${LIQUIBASE_DB_PORT:-55432}"
LIQUIBASE_DB_NAME="${LIQUIBASE_DB_NAME:-geo2}"
LIQUIBASE_DB_USER="${LIQUIBASE_DB_USER:-geo}"
LIQUIBASE_DB_PASSWORD="${LIQUIBASE_DB_PASSWORD:-geo}"

# Force UTF-8 across the shell, JVM, and PostgreSQL client path when Liquibase reads
# formatted SQL files containing multilingual Wikidata labels.
UTF8_LOCALE="${LANG:-C.UTF-8}"
if ! locale -a 2>/dev/null | grep -qi '^c\.utf-8$'; then
  UTF8_LOCALE="${LANG:-en_US.UTF-8}"
fi

export LANG="$UTF8_LOCALE"
export LC_ALL="${LC_ALL:-$UTF8_LOCALE}"
export LANGUAGE="${LANGUAGE:-$UTF8_LOCALE}"
export PGCLIENTENCODING="${PGCLIENTENCODING:-UTF8}"

UTF8_JAVA_FLAGS="-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
export JAVA_OPTS="${JAVA_OPTS:-} ${UTF8_JAVA_FLAGS}"
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} ${UTF8_JAVA_FLAGS}"

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

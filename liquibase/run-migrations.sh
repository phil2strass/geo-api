#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
  echo "Usage: $0 [geo] [liquibase args...]"
}

TARGET="geo"
if [[ $# -gt 0 ]] && [[ "$1" != -* ]]; then
  TARGET="$1"
  shift
fi

LIQUIBASE_ARGS=("$@")
LIQUIBASE_DB_HOST="${LIQUIBASE_DB_HOST:-localhost}"
LIQUIBASE_DB_PORT="${LIQUIBASE_DB_PORT:-55432}"
LIQUIBASE_DB_NAME="${LIQUIBASE_DB_NAME:-geo2}"
LIQUIBASE_DB_USER="${LIQUIBASE_DB_USER:-geo}"
LIQUIBASE_DB_PASSWORD="${LIQUIBASE_DB_PASSWORD:-geo}"

export LIQUIBASE_DB_HOST
export LIQUIBASE_DB_PORT
export LIQUIBASE_DB_NAME
export LIQUIBASE_DB_USER
export LIQUIBASE_DB_PASSWORD

# Force UTF-8 across the shell, JVM, and PostgreSQL client path when Liquibase reads
# formatted SQL files containing multilingual Wikidata labels.
AVAILABLE_LOCALES="$(locale -a 2>/dev/null || true)"
UTF8_LOCALE="$(printf '%s\n' "$AVAILABLE_LOCALES" | grep -Ei '^(c\.utf-?8|.*\.utf-?8)$' | head -n1 || true)"
UTF8_LOCALE="${UTF8_LOCALE:-C}"

export LANG="$UTF8_LOCALE"
export LC_ALL="$UTF8_LOCALE"
export LANGUAGE="${LANGUAGE:-$UTF8_LOCALE}"
export PGCLIENTENCODING="${PGCLIENTENCODING:-UTF8}"

UTF8_JAVA_FLAGS="-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
export JAVA_OPTS="${JAVA_OPTS:-} ${UTF8_JAVA_FLAGS}"
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} ${UTF8_JAVA_FLAGS}"

normalize_liquibase_args() {
  local arg
  local normalized=()

  for arg in "$@"; do
    if [[ "$arg" == -[[:alpha:]]* ]] && [[ "$arg" != --* ]]; then
      normalized+=("--${arg#-}")
    else
      normalized+=("$arg")
    fi
  done

  printf '%s\0' "${normalized[@]}"
}

if [[ ${#LIQUIBASE_ARGS[@]} -gt 0 ]]; then
  mapfile -d '' -t LIQUIBASE_ARGS < <(normalize_liquibase_args "${LIQUIBASE_ARGS[@]}")
fi

run_geo() {
  echo "Running Liquibase for geo2..."
  liquibase \
    --classpath=lib/postgresql.jar \
    --driver=org.postgresql.Driver \
    --url="jdbc:postgresql://${LIQUIBASE_DB_HOST}:${LIQUIBASE_DB_PORT}/${LIQUIBASE_DB_NAME}" \
    --username="${LIQUIBASE_DB_USER}" \
    --password="${LIQUIBASE_DB_PASSWORD}" \
    --changeLogFile=changelog/db.changelog-master.yaml \
    "${LIQUIBASE_ARGS[@]}" \
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

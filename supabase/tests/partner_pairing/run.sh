#!/usr/bin/env bash
# Runs the partner pairing tests against a throwaway local Postgres. No Docker, no Supabase project.
#   supabase/tests/partner_pairing/run.sh
set -euo pipefail
PGBIN="${PGBIN:-/opt/homebrew/opt/postgresql@18/bin}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Unix sockets have a short path limit on macOS, so keep this directory name short.
DIR="$(mktemp -d /tmp/msdb.XXXXXX)"
PORT=54999
cleanup() { "$PGBIN/pg_ctl" -D "$DIR/data" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$DIR"; }
trap cleanup EXIT

"$PGBIN/initdb" -D "$DIR/data" -U postgres --auth=trust >/dev/null
"$PGBIN/pg_ctl" -D "$DIR/data" -o "-p $PORT -k $DIR -c listen_addresses=''" -l "$DIR/log" -w start >/dev/null || { cat "$DIR/log"; exit 1; }
PSQL=("$PGBIN/psql" -h "$DIR" -p "$PORT" -U postgres -X -q -v ON_ERROR_STOP=1)

"${PSQL[@]}" -d postgres -c "create database app" >/dev/null
"${PSQL[@]}" -d app -f "$HERE/stub.sql" -f "${MIGRATION:-$HERE/../../migrations/20261008000001_partner_pairing.sql}" -o /dev/null -f "$HERE/tests.sql"
echo "partner pairing tests: all passed"

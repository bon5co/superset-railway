#!/bin/bash
# Railway wrapper entrypoint for Apache Superset. Runs as the unprivileged `superset` user of the upstream image.
set -eu

fail() { echo "railway-entrypoint: $1" >&2; exit 1; }

[ -n "${ADMIN_PASSWORD:-}" ] || fail "ADMIN_PASSWORD is empty; refusing to start with no administrator password"
[ "${#ADMIN_PASSWORD}" -ge 8 ] || fail "ADMIN_PASSWORD is shorter than 8 characters"
[ -n "${SUPERSET_SECRET_KEY:-}" ] || fail "SUPERSET_SECRET_KEY is empty; Superset signs sessions and encrypts stored connection passwords with it"
[ "${#SUPERSET_SECRET_KEY}" -ge 32 ] || fail "SUPERSET_SECRET_KEY is shorter than 32 characters"
case "$SUPERSET_SECRET_KEY" in
  *CHANGE_ME*|*thisISaSECRET*) fail "SUPERSET_SECRET_KEY is the published default; set a random value" ;;
esac
if [ -z "${SQLALCHEMY_DATABASE_URI:-}" ]; then
  [ -n "${DB_HOST:-}" ] || fail "neither SQLALCHEMY_DATABASE_URI nor DB_HOST is set"
  [ -n "${DB_PASSWORD:-}" ] || fail "DB_PASSWORD is empty"
fi

# Railway injects PORT (8080) and its healthcheck dials that port, so Superset listens on it.
export SUPERSET_PORT="${PORT:-8088}"
export SUPERSET_APP_ROOT="${SUPERSET_APP_ROOT:-/}"

# Wait for the metadata database (the image has no pg_isready; the driver is the probe).
n=0
until python - <<'PY'
import sys
from superset_config import SQLALCHEMY_DATABASE_URI as uri
from sqlalchemy import create_engine, text
try:
    with create_engine(uri).connect() as c:
        c.execute(text("select 1"))
except Exception as e:
    print("railway-entrypoint: database not ready:", type(e).__name__, file=sys.stderr)
    sys.exit(1)
PY
do
  n=$((n + 1)); [ "$n" -lt 90 ] || fail "metadata database never became reachable"
  sleep 2
done

superset db upgrade

# Administrator: create it once; on later boots set the password back to ADMIN_PASSWORD, so the variable stays the truth.
if superset fab list-users 2>/dev/null | grep -q "username:${ADMIN_USERNAME}"; then
  superset fab reset-password --username "$ADMIN_USERNAME" --password "$ADMIN_PASSWORD" >/dev/null
  echo "railway-entrypoint: admin ${ADMIN_USERNAME} exists, password set from ADMIN_PASSWORD"
else
  superset fab create-admin --username "$ADMIN_USERNAME" --firstname Admin --lastname User \
    --email "$ADMIN_EMAIL" --password "$ADMIN_PASSWORD" >/dev/null
  echo "railway-entrypoint: admin ${ADMIN_USERNAME} created"
fi

superset init

echo "railway-entrypoint: listen=0.0.0.0:${SUPERSET_PORT}"
exec /app/docker/entrypoints/run-server.sh

# Loaded by Superset from /app/pythonpath (PYTHONPATH is set by the upstream image).
import os
from urllib.parse import quote_plus

SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]

# Metadata database: a full URI wins; otherwise build it from the postgres service's host and password.
SQLALCHEMY_DATABASE_URI = os.environ.get("SQLALCHEMY_DATABASE_URI") or "postgresql+psycopg2://{u}:{p}@{h}:{port}/{d}".format(
    u=quote_plus(os.environ.get("DB_USER", "superset")),
    p=quote_plus(os.environ["DB_PASSWORD"]),
    h=os.environ["DB_HOST"],
    port=os.environ.get("DB_PORT", "5432"),
    d=os.environ.get("DB_NAME", "superset"),
)

# Railway's edge terminates TLS and forwards X-Forwarded-Proto / -Host; without this Superset builds http:// links.
ENABLE_PROXY_FIX = True

# Apache Superset on Railway: thin wrapper over the official image.
# What it adds: the Postgres driver the upstream image does not ship (psycopg2-binary), a boot-time administrator
# from one generated password (upstream leaves you to run `superset fab create-admin` by hand in a shell),
# `superset db upgrade` and `superset init` on every boot, the Railway-injected PORT, the metadata database URL
# assembled from the postgres service, proxy headers trusted so https links are right behind Railway's edge,
# and a refusal to boot with an empty or default secret.
# upstream: apache/superset
FROM apache/superset:6.1.0@sha256:16b50bbef6648912a79e3293d418fefa743ce555d36c5af6b85d859119ed7f88

USER root
RUN uv pip install --python /app/.venv/bin/python --no-cache psycopg2-binary==2.9.10

COPY superset_config.py /app/pythonpath/superset_config.py
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0644 /app/pythonpath/superset_config.py && chmod 0755 /usr/local/bin/railway-entrypoint.sh

ENV ADMIN_USERNAME=admin \
    ADMIN_EMAIL=admin@example.com \
    DB_USER=superset \
    DB_NAME=superset \
    SCARF_ANALYTICS=false

USER superset
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]

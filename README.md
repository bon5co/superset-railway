# superset-railway

Thin Railway wrapper over [apache/superset](https://github.com/apache/superset) 6.1.0: the Postgres driver the upstream
image lacks, a boot-time administrator from one generated password, `db upgrade` and `init` on every boot, Railway `PORT`,
proxy headers trusted, metadata database URL assembled from a Postgres service. Image: `ghcr.io/bon5co/superset-railway`.

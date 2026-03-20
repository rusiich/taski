#!/bin/sh
set -e

echo "[entrypoint] wait for db..."
python - <<'PY'
import os, time, sys
import psycopg2

host = os.getenv("POSTGRES_HOST", "db")
port = int(os.getenv("POSTGRES_PORT", "5432"))
user = os.getenv("POSTGRES_USER")
password = os.getenv("POSTGRES_PASSWORD")
dbname = os.getenv("POSTGRES_DB")

for i in range(60):
    try:
        psycopg2.connect(host=host, port=port, user=user, password=password, dbname=dbname).close()
        print("DB is up")
        sys.exit(0)
    except Exception as e:
        time.sleep(1)
print("DB is still down after 60s")
sys.exit(1)
PY

echo "[entrypoint] migrate..."
python manage.py migrate --noinput

echo "[entrypoint] collectstatic..."
python manage.py collectstatic --noinput

echo "[entrypoint] start gunicorn..."
exec gunicorn --bind 0.0.0.0:8000 backend.wsgi:application

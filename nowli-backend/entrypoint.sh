#!/bin/sh
set -e

echo "Starting Django entrypoint script..."

# 1. Wait for database (only if DB_HOST is set — used with AWS RDS or any external PG)
if [ -n "$DB_HOST" ]; then
  echo "Waiting for PostgreSQL at $DB_HOST:${DB_PORT:-5432}..."
  # Use Python + psycopg2 to test a real connection (more reliable than nc for RDS)
  RETRIES=30
  until python -c "
import sys, os
import psycopg2
try:
    psycopg2.connect(
        dbname=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        host=os.environ['DB_HOST'],
        port=os.environ.get('DB_PORT', '5432'),
        connect_timeout=5,
    )
    print('DB connection successful.')
    sys.exit(0)
except Exception as e:
    print(f'DB not ready: {e}')
    sys.exit(1)
" 2>&1; do
    RETRIES=$((RETRIES - 1))
    if [ "$RETRIES" -le 0 ]; then
      echo "ERROR: Could not connect to database after multiple retries. Exiting."
      exit 1
    fi
    echo "Retrying in 2 seconds... ($RETRIES retries left)"
    sleep 2
  done
fi

# 2. Apply database migrations
echo "Running migrations..."
python manage.py migrate --noinput

# 3. Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear

# 4. Create superuser only if credentials are provided
# 4. Create superuser only if credentials are provided
if [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
  echo "Attempting to create superuser ($DJANGO_SUPERUSER_EMAIL)..."
  python manage.py createsuperuser --noinput 2>&1 || echo "Superuser creation skipped (likely already exists)."
else
  echo "Skipping superuser creation - DJANGO_SUPERUSER_EMAIL or DJANGO_SUPERUSER_PASSWORD not provided"
fi

echo "Entrypoint script completed successfully!"

# 5. Execute the CMD from Dockerfile
exec "$@"
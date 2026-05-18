#!/bin/sh
set -e

is_railway() {
  [ -n "$RAILWAY_ENVIRONMENT" ] || [ -n "$RAILWAY_PROJECT_ID" ] || [ -n "$RAILWAY_SERVICE_ID" ]
}

if [ -n "$DATABASE_URL" ]; then
  echo "Waiting for database..."
  attempts=0
  max_attempts=45
  until php bin/console doctrine:query:sql "SELECT 1" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge "$max_attempts" ]; then
      echo "WARNING: Database not ready after ${max_attempts} attempts. Continuing anyway."
      break
    fi
    sleep 2
  done

  if [ "$attempts" -lt "$max_attempts" ]; then
    echo "Database is ready."
    php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true
  fi
fi

chown -R www-data:www-data var
chmod -R 775 var

if is_railway; then
  PORT="${PORT:-80}"
  echo "Starting Railway mode on 0.0.0.0:${PORT}..."
  sed "s/listen 0.0.0.0:80;/listen 0.0.0.0:${PORT};/" \
    /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
  nginx -t
  php-fpm -D
  exec nginx -g 'daemon off;'
fi

php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod
php bin/console asset-map:compile --env=prod

chown -R www-data:www-data var
chmod -R 775 var

exec "$@"

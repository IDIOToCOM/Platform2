#!/bin/sh
set -e

if [ -n "$DATABASE_URL" ]; then
  echo "Waiting for database..."
  until php bin/console doctrine:query:sql "SELECT 1" >/dev/null 2>&1; do
    sleep 2
  done
  echo "Database is ready."

  php bin/console doctrine:migrations:migrate --no-interaction --env=prod
fi

php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod
php bin/console asset-map:compile --env=prod

chown -R www-data:www-data var
chmod -R 775 var

# Railway sets PORT — run Nginx + PHP-FPM in one container
if [ -n "$PORT" ]; then
  echo "Starting Railway mode on port ${PORT}..."
  sed "s/listen 80;/listen ${PORT};/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
  php-fpm -D
  exec nginx -g 'daemon off;'
fi

exec "$@"

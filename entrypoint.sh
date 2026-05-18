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

exec "$@"

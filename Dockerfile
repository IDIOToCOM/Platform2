FROM php:8.3-fpm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    && docker-php-ext-install \
        pdo_mysql \
        intl \
        opcache \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV APP_SECRET=change_me_in_production

COPY composer.json composer.lock symfony.lock ./

RUN composer install --no-dev --no-scripts --prefer-dist --no-interaction

COPY . .

RUN composer dump-autoload --optimize --classmap-authoritative --no-interaction \
    && php bin/console assets:install public --env=prod --no-debug \
    && php bin/console importmap:install --env=prod --no-debug \
    && php bin/console cache:clear --env=prod --no-debug \
    && php bin/console asset-map:compile --env=prod --no-debug

RUN mkdir -p var/cache var/log \
    && chown -R www-data:www-data var \
    && chmod -R 775 var

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]

FROM php:8.2-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        gosu \
        unzip \
        libcap2-bin \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        pdo_mysql \
        zip \
    && a2enmod rewrite \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts

COPY . .

RUN chown -R www-data:www-data storage bootstrap/cache

COPY docker/entrypoint.sh /usr/local/bin/akaunting-entrypoint
RUN chmod +x /usr/local/bin/akaunting-entrypoint

ENTRYPOINT ["/usr/local/bin/akaunting-entrypoint"]
CMD ["apache2-foreground"]

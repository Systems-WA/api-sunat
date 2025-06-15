FROM surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small as wkhtmltopdf

FROM php:8.2-fpm-alpine

# Variables de entorno
ENV APP_ENV=prod
ENV APP_SECRET=
ENV WKHTMLTOPDF_PATH=wkhtmltopdf
ENV CLIENT_TOKEN=
ENV SOL_USER=
ENV SOL_PASS=
ENV CORS_ALLOW_ORIGIN=.
# ENV FE_URL=
# ENV RE_URL=
# ENV GUIA_URL=
# ENV AUTH_URL=
# ENV API_URL=
# ENV CLIENT_ID=
# ENV CLIENT_SECRET=
ENV TRUSTED_PROXIES="127.0.0.1,REMOTE_ADDR"

# Copiar wkhtmltopdf
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /usr/bin/

# Instalar extensiones y dependencias
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    icu-dev \
    libzip-dev \
    libxml2-dev \
    oniguruma-dev \
    ttf-freefont \
    fontconfig \
    libx11 \
    libxrender \
    libxcb \
    bash \
    && docker-php-ext-install intl zip gd exif soap

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# App directory
WORKDIR /var/www/html

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && mkdir -p var/cache var/log \
    && chown -R www-data:www-data var vendor

EXPOSE 9000

CMD ["php-fpm"]
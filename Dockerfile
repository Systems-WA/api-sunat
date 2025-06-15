FROM surnet/alpine-wkhtmltopdf:3.17.0-0.12.6-small AS wkhtmltopdf

FROM php:8.2-fpm-alpine

# Copiar wkhtmltopdf
COPY --from=wkhtmltopdf /bin/wkhtmltopdf /usr/bin/

# Instalar extensiones y dependencias
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
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
    && docker-php-ext-install intl zip gd exif soap

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Copia configuración de nginx y supervisord
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

# App directory
WORKDIR /var/www/html
COPY . .

# Expone puerto HTTP
EXPOSE 80

# Eliminar el default.conf conflictivo
RUN rm -f /etc/nginx/http.d/default.conf

# Instalar dependencias de PHP y preparar permisos
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && mkdir -p var/cache var/log /var/lib/nginx/tmp/client_body \
    && chown -R www-data:www-data var vendor /var/lib/nginx \
    && find /var/lib/nginx -type d -exec chmod 755 {} \; \
    && find /var/lib/nginx -type f -exec chmod 644 {} \;

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
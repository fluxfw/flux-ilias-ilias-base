ARG PHP_VERSION
FROM php:$PHP_VERSION-fpm-alpine

RUN apk add --no-cache curl ffmpeg freetype-dev ghostscript imagemagick libjpeg-turbo-dev libpng-dev libxslt-dev libzip-dev mariadb-client openldap-dev patch su-exec unzip zlib-dev zip && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd ldap mysqli pdo_mysql soap xsl zip && \
    case $PHP_VERSION in 8.*) (mkdir -p /usr/src/php/ext/xmlrpc && cd /usr/src/php/ext/xmlrpc && wget -O - https://pecl.php.net/get/xmlrpc | tar -xz --strip-components=1) ;; esac && docker-php-ext-install -j$(nproc) xmlrpc && \
    docker-php-source delete && \
    apk del .build-deps

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV ILIAS_PHP_MEMORY_LIMIT 300M
RUN echo "memory_limit = $ILIAS_PHP_MEMORY_LIMIT" > "$PHP_INI_DIR/conf.d/ilias.ini"

ENV ILIAS_WEB_DIR /var/www/html
RUN mkdir -p "$ILIAS_WEB_DIR" && chown www-data:www-data -R "$ILIAS_WEB_DIR"

ENV ILIAS_FILESYSTEM_DATA_DIR /var/iliasdata
RUN mkdir -p "$ILIAS_FILESYSTEM_DATA_DIR" && chown www-data:www-data -R "$ILIAS_FILESYSTEM_DATA_DIR"

ENV ILIAS_FILESYSTEM_WEB_DATA_DIR $ILIAS_FILESYSTEM_DATA_DIR/web
RUN mkdir -p "$ILIAS_FILESYSTEM_WEB_DATA_DIR" && chown www-data:www-data -R "$ILIAS_FILESYSTEM_WEB_DATA_DIR"

ENV ILIAS_LOG_DIR /var/log/ilias
RUN mkdir -p "$ILIAS_LOG_DIR" && chown www-data:www-data -R "$ILIAS_LOG_DIR"

ENV _ILIAS_WEB_DATA_DIR $ILIAS_WEB_DIR/data
RUN ln -sfT "$ILIAS_FILESYSTEM_WEB_DATA_DIR" "$_ILIAS_WEB_DATA_DIR" && chown -h www-data:www-data "$_ILIAS_WEB_DATA_DIR"

ENV ILIAS_FILESYSTEM_INI_PHP_FILE $ILIAS_FILESYSTEM_DATA_DIR/ilias.ini.php
ENV _ILIAS_WEB_PHP_FILE $ILIAS_WEB_DIR/ilias.ini.php
RUN ln -sfT "$ILIAS_FILESYSTEM_INI_PHP_FILE" "$_ILIAS_WEB_PHP_FILE" && chown -h www-data:www-data "$_ILIAS_WEB_PHP_FILE"

ENTRYPOINT ["/flux-ilias-ilias-base/bin/server.sh"]

COPY . /flux-ilias-ilias-base

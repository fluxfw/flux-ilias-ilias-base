ARG PHP_VERSION
FROM php:$PHP_VERSION-fpm-alpine

LABEL org.opencontainers.image.source="https://github.com/fluxfw/flux-ilias-ilias-base"

RUN apk add --no-cache curl ffmpeg freetype-dev ghostscript imagemagick libjpeg-turbo-dev libpng-dev libxslt-dev libzip-dev mariadb-client openldap-dev patch su-exec unzip zlib-dev zip && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    (mkdir -p /usr/src/php/ext/apcu && cd /usr/src/php/ext/apcu && wget -O - https://pecl.php.net/get/apcu | tar -xz --strip-components=1) && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) apcu gd ldap mysqli pdo_mysql soap xsl zip && \
    case $PHP_VERSION in 8.*) (mkdir -p /usr/src/php/ext/xmlrpc && cd /usr/src/php/ext/xmlrpc && wget -O - https://pecl.php.net/get/xmlrpc | tar -xz --strip-components=1) ;; esac && docker-php-ext-install -j$(nproc) xmlrpc && \
    docker-php-source delete && \
    apk del .build-deps

#ENV ILIAS_PDFGENERATION_PATH_TO_PHANTOM_JS /usr/local/bin/phantomjs
#RUN wget -O - https://github.com/dustinblackman/phantomized/releases/download/2.1.1a/dockerized-phantomjs.tar.gz | tar -xz -C / && \
#    (mkdir -p /tmp/phantomjs && cd /tmp/phantomjs && wget -O - https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -xj --strip-components=1 && mv bin/phantomjs #$ILIAS_PDFGENERATION_PATH_TO_PHANTOM_JS && rm -rf /tmp/phantomjs)

ENV ILIAS_STYLE_PATH_TO_LESSC /usr/share/lessphp/plessc
RUN (mkdir -p "$(dirname $ILIAS_STYLE_PATH_TO_LESSC)" && cd "$(dirname $ILIAS_STYLE_PATH_TO_LESSC)" && wget -O - https://github.com/leafo/lessphp/archive/refs/tags/v0.5.0.tar.gz | tar -xz --strip-components=1 && sed -i "s/{0}/[0]/" lessc.inc.php)

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV ILIAS_PHP_MEMORY_LIMIT 300M
RUN echo "memory_limit = $ILIAS_PHP_MEMORY_LIMIT" > "$PHP_INI_DIR/conf.d/ilias.ini"

ENV ILIAS_WEB_DIR /var/www/html
RUN mkdir -p "$ILIAS_WEB_DIR" && chown www-data:www-data -R "$ILIAS_WEB_DIR"

ENV ILIAS_FILESYSTEM_DATA_DIR /var/iliasdata
RUN mkdir -p "$ILIAS_FILESYSTEM_DATA_DIR" && chown www-data:www-data -R "$ILIAS_FILESYSTEM_DATA_DIR"
VOLUME $ILIAS_FILESYSTEM_DATA_DIR

ENV ILIAS_FILESYSTEM_WEB_DATA_DIR $ILIAS_FILESYSTEM_DATA_DIR/web
RUN mkdir -p "$ILIAS_FILESYSTEM_WEB_DATA_DIR" && chown www-data:www-data -R "$ILIAS_FILESYSTEM_WEB_DATA_DIR"

ENV ILIAS_LOG_DIR /var/log/ilias
RUN mkdir -p "$ILIAS_LOG_DIR" && chown www-data:www-data -R "$ILIAS_LOG_DIR"
VOLUME $ILIAS_LOG_DIR

ENV _ILIAS_WEB_DATA_DIR $ILIAS_WEB_DIR/data
RUN ln -sfT "$ILIAS_FILESYSTEM_WEB_DATA_DIR" "$_ILIAS_WEB_DATA_DIR" && chown -h www-data:www-data "$_ILIAS_WEB_DATA_DIR"

ENV ILIAS_FILESYSTEM_INI_PHP_FILE $ILIAS_FILESYSTEM_DATA_DIR/ilias.ini.php
ENV _ILIAS_WEB_PHP_FILE $ILIAS_WEB_DIR/ilias.ini.php
RUN ln -sfT "$ILIAS_FILESYSTEM_INI_PHP_FILE" "$_ILIAS_WEB_PHP_FILE" && chown -h www-data:www-data "$_ILIAS_WEB_PHP_FILE"

ENV ILIAS_PHP_PORT 9000
EXPOSE $ILIAS_PHP_PORT

ENTRYPOINT ["/flux-ilias-ilias-base/bin/docker-entrypoint.sh"]

COPY . /flux-ilias-ilias-base

ARG COMMIT_SHA
LABEL org.opencontainers.image.revision="$COMMIT_SHA"

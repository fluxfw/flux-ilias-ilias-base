ARG APCU_SOURCE_URL=https://pecl.php.net/get/apcu
ARG COMPOSER1_IMAGE=composer:1
ARG COMPOSER2_IMAGE=composer:latest
ARG LESSPHP_SOURCE_URL=https://github.com/leafo/lessphp/archive/refs/tags/v0.5.0.tar.gz
ARG PHANTOMJS_ALPINE_PATCH_SOURCE_URL=https://github.com/dustinblackman/phantomized/releases/download/2.1.1a/dockerized-phantomjs.tar.gz
ARG PHANTOMJS_SOURCE_URL=https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
ARG PHP_FPM_IMAGE=php:fpm-alpine
ARG PHP8_XMLRPC_SOURCE_URL=https://pecl.php.net/get/xmlrpc

FROM $COMPOSER1_IMAGE AS composer1

FROM $COMPOSER2_IMAGE AS composer2

FROM $PHP_FPM_IMAGE
ARG APCU_SOURCE_URL
ARG LESSPHP_SOURCE_URL
ARG PHANTOMJS_ALPINE_PATCH_SOURCE_URL
ARG PHANTOMJS_SOURCE_URL
ARG PHP8_XMLRPC_SOURCE_URL

LABEL org.opencontainers.image.source="https://github.com/fluxapps/flux-ilias-ilias-base"
LABEL maintainer="fluxlabs <support@fluxlabs.ch> (https://fluxlabs.ch)"

RUN apk add --no-cache curl ffmpeg freetype-dev ghostscript imagemagick libjpeg-turbo-dev libpng-dev libxslt-dev libzip-dev mariadb-client openldap-dev patch su-exec unzip zlib-dev zip && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    (mkdir -p /usr/src/php/ext/apcu && cd /usr/src/php/ext/apcu && wget -O - $APCU_SOURCE_URL | tar -xz --strip-components=1) && \
    case $PHP_VERSION in 8.*|7.4*) docker-php-ext-configure gd --with-freetype --with-jpeg ;; *) docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ ;; esac && \
    docker-php-ext-install -j$(nproc) apcu gd ldap mysqli pdo_mysql soap xsl zip && \
    case $PHP_VERSION in 8.*) (mkdir -p /usr/src/php/ext/xmlrpc && cd /usr/src/php/ext/xmlrpc && wget -O - $PHP8_XMLRPC_SOURCE_URL | tar -xz --strip-components=1) ;; esac && docker-php-ext-install -j$(nproc) xmlrpc && \
    docker-php-source delete && \
    apk del .build-deps

ENV ILIAS_PDFGENERATION_PATH_TO_PHANTOM_JS /usr/local/bin/phantomjs
RUN wget -O - $PHANTOMJS_ALPINE_PATCH_SOURCE_URL | tar -xz -C / && \
    (mkdir -p /tmp/phantomjs && cd /tmp/phantomjs && wget -O - $PHANTOMJS_SOURCE_URL | tar -xj --strip-components=1 && mv bin/phantomjs $ILIAS_PDFGENERATION_PATH_TO_PHANTOM_JS && rm -rf /tmp/phantomjs)

ENV ILIAS_STYLE_PATH_TO_LESSC /usr/share/lessphp/plessc
RUN (mkdir -p "$(dirname $ILIAS_STYLE_PATH_TO_LESSC)" && cd "$(dirname $ILIAS_STYLE_PATH_TO_LESSC)" && wget -O - $LESSPHP_SOURCE_URL | tar -xz --strip-components=1 && sed -i "s/{0}/[0]/" lessc.inc.php)

COPY --from=composer1 /usr/bin/composer /usr/bin/composer1
COPY --from=composer2 /usr/bin/composer /usr/bin/composer2

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

ENTRYPOINT ["/flux-ilias-ilias-base/bin/entrypoint.sh"]

COPY . /flux-ilias-ilias-base

#!/usr/bin/env sh

set -e

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS && \
    (mkdir -p /usr/src/php/ext/apcu && cd /usr/src/php/ext/apcu && wget -O - https://pecl.php.net/get/apcu | tar -xz --strip-components=1) && \
    docker-php-ext-install -j$(nproc) apcu && \
    docker-php-source delete && \
    apk del .build-deps

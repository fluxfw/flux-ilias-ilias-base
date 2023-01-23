#!/usr/bin/env sh

set -e

# https://github.com/Surnet/docker-wkhtmltopdf#other-images

apk add --no-cache libstdc++ libx11 libxrender libxext libssl1.1 ca-certificates fontconfig freetype ttf-dejavu ttf-droid ttf-freefont ttf-liberation && \
apk add --no-cache --virtual .build-deps msttcorefonts-installer && \
update-ms-fonts && fc-cache -f && \
apk del .build-deps

#COPY --from=surnet/alpine-wkhtmltopdf:3.16.2-0.12.6-small /bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

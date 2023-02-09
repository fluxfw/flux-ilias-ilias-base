#!/usr/bin/env sh

set -e

bin="`dirname "$0"`"
root="$bin/.."

name="`basename "$(realpath "$root")"`"
user="${FLUX_PUBLISH_DOCKER_USER:=fluxfw}"
image="$user/$name"

for php_version in 7.4 8.0; do
    docker build "$root" --pull --build-arg PHP_VERSION=$php_version -t "$image:php$php_version"
done
docker tag "$image:php7.4" "$image:latest"

#!/usr/bin/env sh

set -e

version="$1"
if [ -z "$version" ]; then
    echo "Please pass an ILIAS core version" >&2
    exit 1
fi

/flux-ilias-ilias-base/bin/install-archive.sh "https://github.com/ILIAS-eLearning/ILIAS/releases/download/v$version/ILIAS-$version.tar.gz" "$ILIAS_WEB_DIR"

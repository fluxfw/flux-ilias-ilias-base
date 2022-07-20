#!/usr/bin/env sh

set -e

version="$1"
if [ -z "$version" ]; then
    echo "Please pass a ILIAS core version"
    exit 1
fi

echo "Download ILIAS core $version and extract it to $ILIAS_WEB_DIR"

(cd $ILIAS_WEB_DIR && wget -O - "https://github.com/ILIAS-eLearning/ILIAS/releases/download/v$version/ILIAS-$version.tar.gz" | tar -xz --strip-components=1)

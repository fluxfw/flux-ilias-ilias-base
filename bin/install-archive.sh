#!/usr/bin/env sh

set -e

url="$1"
if [ -z "$url" ]; then
    echo "Please pass an url" >&2
    exit 1
fi

folder="$2"
if [ -z "$folder" ]; then
    echo "Please pass a folder" >&2
    exit 1
fi

echo "Download $url and extract it to $folder"

(mkdir -p "$folder" && cd "$folder" && wget -O - "$url" | tar -xz --strip-components=1)

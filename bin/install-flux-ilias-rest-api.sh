#!/usr/bin/env sh

set -e

tag="$1"
if [ -z "$tag" ]; then
    echo "Please pass a flux-ilias-rest-api tag"
    exit 1
fi

/flux-ilias-ilias-base/bin/install-archive.sh "https://github.com/fluxfw/flux-ilias-rest-api/releases/download/$tag/flux-ilias-rest-api-$tag-build.tar.gz" "$ILIAS_WEB_DIR/Customizing/global/flux-ilias-rest-api"

if [ ! -d "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/UIComponent/UserInterfaceHook/flux_ilias_rest_helper_plugin" ]; then
    echo "Hint: You need to install flux-ilias-rest-helper-plugin too"
fi

echo "Hint: You need to call /flux-ilias-nginx-base/bin/install-flux-ilias-rest-api.sh in flux-ilias-nginx-base too"

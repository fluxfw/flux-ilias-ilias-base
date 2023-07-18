#!/usr/bin/env sh

set -e

tag="$1"
if [ -z "$tag" ]; then
    echo "Please pass a flux-ilias-rest-object-helper-plugin tag" >&2
    exit 1
fi

/flux-ilias-ilias-base/bin/install-archive.sh "https://github.com/fluxfw/flux-ilias-rest-object-helper-plugin/releases/download/$tag/flux-ilias-rest-object-helper-plugin-$tag-build.tar.gz" "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/Repository/RepositoryObject/flux_ilias_rest_object_helper_plugin"

if [ ! -d "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/UIComponent/UserInterfaceHook/flux_ilias_rest_helper_plugin" ]; then
    echo "Hint: You need to install flux-ilias-rest-helper-plugin too"
fi

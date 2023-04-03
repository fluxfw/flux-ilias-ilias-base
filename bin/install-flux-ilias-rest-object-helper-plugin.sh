#!/usr/bin/env sh

set -e

versionIsGreaterOrEqual() {
    if [ -n "$1" ] && [ -n "$2" ] && [ `echo -e "$2\n$1" | sort -rV | head -n 1)` = "$1" ]; then
        echo "true"
    else
        echo "false"
    fi
}

tag="$1"
if [ -z "$tag" ]; then
    echo "Please pass a flux-ilias-rest-object-helper-plugin tag" >&2
    exit 1
fi

/flux-ilias-ilias-base/bin/install-archive.sh "https://github.com/fluxfw/flux-ilias-rest-object-helper-plugin/releases/download/$tag/flux-ilias-rest-object-helper-plugin-$tag-build.tar.gz" "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/Repository/RepositoryObject/flux_ilias_rest_object_helper_plugin"

if [ ! -d "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/UIComponent/UserInterfaceHook/flux_ilias_rest_helper_plugin" ]; then
    echo "Hint: You need to install flux-ilias-rest-helper-plugin too"
fi

if [ `versionIsGreaterOrEqual "$ilias_version_number" 8.0` = "true" ]; then
    echo "Hint: For make this plugin work with the broken ILIAS 8 core repository plugins interface, you may need to patch the core, before you update the plugin (At your own risk)"
fi

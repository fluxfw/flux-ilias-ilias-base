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
    echo "Please pass a flux-ilias-rest-helper-plugin tag"
    exit 1
fi

ilias_version_number=`/flux-ilias-ilias-base/bin/get_ilias_version_number.php`

/flux-ilias-ilias-base/bin/download-archive.sh "https://github.com/fluxfw/flux-ilias-rest-helper-plugin/releases/download/$tag/flux-ilias-rest-helper-plugin-$tag-build.tar.gz" "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/UIComponent/UserInterfaceHook/flux_ilias_rest_helper_plugin"

if [ ! -d "$ILIAS_WEB_DIR/Customizing/global/flux-ilias-rest-api" ]; then
    echo "Hint: You need to download flux-ilias-rest-api too"
fi

if [ `versionIsGreaterOrEqual "$ilias_version_number" 8.0` = "false" ] && [ ! -d "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/Cron/CronHook/flux_ilias_rest_leg_cron_helper_plugin" ]; then
    echo "Hint: You need to download flux-ilias-rest-legacy-cron-helper-plugin too"
fi

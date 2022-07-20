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
    echo "Please pass a flux-ilias-rest-legacy-cron-helper-plugin tag"
    exit 1
fi

ilias_version_number=`/flux-ilias-ilias-base/bin/get_ilias_version_number.php`

if [ `versionIsGreaterOrEqual "$ilias_version_number" 8.0` = "true" ]; then
    echo "Hint: flux-ilias-rest-legacy-cron-helper-plugin is only needed for ILIAS 6 or 7"
fi

/flux-ilias-ilias-base/bin/install-archive.sh "https://github.com/fluxfw/flux-ilias-rest-legacy-cron-helper-plugin/releases/download/$tag/flux-ilias-rest-legacy-cron-helper-plugin-$tag-build.tar.gz" "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/Cron/CronHook/flux_ilias_rest_leg_cron_helper_plugin"

if [ ! -d "$ILIAS_WEB_DIR/Customizing/global/plugins/Services/UIComponent/UserInterfaceHook/flux_ilias_rest_helper_plugin" ]; then
    echo "Hint: You need to install flux-ilias-rest-helper-plugin too"
fi

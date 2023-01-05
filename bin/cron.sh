#!/usr/bin/env sh

set -e

. /flux-ilias-ilias-base/src/functions.sh

checkIliasSourceCode

checkIliasVersionNumber

until [ -f "$ILIAS_FILESYSTEM_INI_PHP_FILE" ] && [ -d "$ILIAS_FILESYSTEM_WEB_DATA_DIR/$ILIAS_COMMON_CLIENT_ID/usr_images" ]; do
    echo "ILIAS not configured yet"
    echo "Waiting 60 seconds for check again"
    sleep 60
done
echo "ILIAS config found"

auto_skip_config_temp_file=/tmp/auto_skip_config_temp_file
if [ -f "$auto_skip_config_temp_file" ]; then
    echo "Auto skip config (This is not a new container (re)creation)"
else
    echo "Run config"

    echo "Generate cron config"
    echo "$ILIAS_CRON_PERIOD /flux-ilias-ilias-base/bin/run_ilias_cron.sh" > /etc/crontabs/www-data

    echo "Ensure ILIAS $ILIAS_CRON_USER_LOGIN user exists"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/ensure_ilias_user_exists.php "$ILIAS_CRON_USER_LOGIN" "$(getFileEnv ILIAS_CRON_USER_PASSWORD)"

    echo "Config finished"
    echo "Skip it until a new container (re)creation"
    touch "$auto_skip_config_temp_file"
fi

echo "Start cron"
exec crond -f

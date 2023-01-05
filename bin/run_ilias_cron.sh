#!/usr/bin/env sh

set -e

. /flux-ilias-ilias-base/src/functions.sh

exec php "$ILIAS_WEB_DIR/cron/cron.php" "$ILIAS_CRON_USER_LOGIN" "$(getFileEnv ILIAS_CRON_USER_PASSWORD)" "$ILIAS_COMMON_CLIENT_ID"

#!/usr/bin/env sh

set -e

exec php "$ILIAS_WEB_DIR/setup/cli.php" "$@"

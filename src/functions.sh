#!/usr/bin/env sh

set -e

checkIliasSourceCode() {
    if [ ! -f "$ILIAS_WEB_DIR/ilias.php" ]; then
        echo "Please provide ILIAS source code to $ILIAS_WEB_DIR"
        exit 1
    fi
}

checkIliasVersionNumber() {
    ilias_version_number=`/flux-ilias-ilias-base/bin/get_ilias_version_number.php`
    echo "Your ILIAS version number is $ilias_version_number"

    if [ `versionIsGreaterOrEqual "$ilias_version_number" 7.0` = "false" ]; then
        echo "You need at least ILIAS 7"
        echo "Older ILIAS versions are not supported"
        exit 1
    fi
}

checkWwwData() {
    if su-exec www-data:www-data test -w "$1"; then
        echo "true"
    else
        echo "false"
    fi
}

ensureWwwData() {
    mkdir -p "$1"
    until [ `checkWwwData "$1"` = "true" ]; do
        echo "www-data can not write to $1"
        echo "Please manually run the follow command like"
        echo "docker exec -u root:root `hostname` chown www-data:www-data -R $1"
        echo "Waiting 30 seconds for check again"
        sleep 30
    done
    echo "www-data can write to $1"
}

ensureSymlink() {
        echo "Ensure $2 is symlink to $1"
        ln -sfT "$1" "$2"
        chown -h www-data:www-data "$2"
}

getFileEnv() {
    name="$1"
    value=`printenv "$name"`
    if [ -n "$value" ]; then
        echo -n "$value"
    else
        name_file="${name}_FILE"
        value_file=`printenv "$name_file"`
        if [ -n "$value_file" ] && [ -f "$value_file" ]; then
            echo -n "`cat "$value_file"`"
        fi
    fi
}

hashPassword() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

versionIsGreaterOrEqual() {
    if [ -n "$1" ] && [ -n "$2" ] && [ `echo -e "$2\n$1" | sort -rV | head -n 1)` = "$1" ]; then
        echo "true"
    else
        echo "false"
    fi
}

ILIAS_PHP_DISPLAY_ERRORS="${ILIAS_PHP_DISPLAY_ERRORS:=Off}"
ILIAS_PHP_ERROR_REPORTING="${ILIAS_PHP_ERROR_REPORTING:=E_ALL & ~E_NOTICE & ~E_WARNING & ~E_STRICT}"
ILIAS_PHP_EXPOSE="${ILIAS_PHP_EXPOSE:=Off}"
ILIAS_PHP_LISTEN="${ILIAS_PHP_LISTEN:=0.0.0.0}"
ILIAS_PHP_LOG_ERRORS="${ILIAS_PHP_LOG_ERRORS:=On}"
ILIAS_PHP_MAX_EXECUTION_TIME="${ILIAS_PHP_MAX_EXECUTION_TIME:=900}"
ILIAS_PHP_MAX_INPUT_TIME="${ILIAS_PHP_MAX_INPUT_TIME:=900}"
ILIAS_PHP_MAX_INPUT_VARS="${ILIAS_PHP_MAX_INPUT_VARS:=1000}"
ILIAS_PHP_POST_MAX_SIZE="${ILIAS_PHP_POST_MAX_SIZE:=200M}"
ILIAS_PHP_UPLOAD_MAX_SIZE="${ILIAS_PHP_UPLOAD_MAX_SIZE:=200M}"

ILIAS_CONFIG_FILE="${ILIAS_CONFIG_FILE:=$ILIAS_FILESYSTEM_DATA_DIR/config.json}" && export ILIAS_CONFIG_FILE

ILIAS_COMMON_CLIENT_ID="${ILIAS_COMMON_CLIENT_ID:=default}" && export ILIAS_COMMON_CLIENT_ID

ILIAS_DATABASE_HOST="${ILIAS_DATABASE_HOST:=database}" && export ILIAS_DATABASE_HOST
ILIAS_DATABASE_DATABASE="${ILIAS_DATABASE_DATABASE:=ilias}" && export ILIAS_DATABASE_DATABASE
ILIAS_DATABASE_USER="${ILIAS_DATABASE_USER:=ilias}" && export ILIAS_DATABASE_USER

ILIAS_LOGGING_ENABLE="${ILIAS_LOGGING_ENABLE:=true}" && export ILIAS_LOGGING_ENABLE
ILIAS_LOGGING_PATH_TO_LOGFILE="${ILIAS_LOGGING_PATH_TO_LOGFILE:=$ILIAS_LOG_DIR/ilias.log}" && export ILIAS_LOGGING_PATH_TO_LOGFILE
ILIAS_LOGGING_ERRORLOG_DIR="${ILIAS_LOGGING_ERRORLOG_DIR:=$ILIAS_LOG_DIR/errors}" && export ILIAS_LOGGING_ERRORLOG_DIR

ILIAS_MEDIAOBJECT_PATH_TO_FFMPEG="${ILIAS_MEDIAOBJECT_PATH_TO_FFMPEG:=/usr/bin/ffmpeg}" && export ILIAS_MEDIAOBJECT_PATH_TO_FFMPEG

ILIAS_PREVIEW_PATH_TO_GHOSTSCRIPT="${ILIAS_PREVIEW_PATH_TO_GHOSTSCRIPT:=/usr/bin/gs}" && export ILIAS_PREVIEW_PATH_TO_GHOSTSCRIPT

ILIAS_STYLE_PATH_TO_LESSC="${ILIAS_STYLE_PATH_TO_LESSC:=/usr/bin/lessc}" && export ILIAS_STYLE_PATH_TO_LESSC

ILIAS_UTILITIES_PATH_TO_CONVERT="${ILIAS_UTILITIES_PATH_TO_CONVERT:=/usr/bin/convert}" && export ILIAS_UTILITIES_PATH_TO_CONVERT
ILIAS_UTILITIES_PATH_TO_ZIP="${ILIAS_UTILITIES_PATH_TO_ZIP:=/usr/bin/zip}" && export ILIAS_UTILITIES_PATH_TO_ZIP
ILIAS_UTILITIES_PATH_TO_UNZIP="${ILIAS_UTILITIES_PATH_TO_UNZIP:=/usr/bin/unzip}" && export ILIAS_UTILITIES_PATH_TO_UNZIP

ILIAS_WEBSERVICES_RPC_SERVER_HOST="${ILIAS_WEBSERVICES_RPC_SERVER_HOST:=ilserver}" && export ILIAS_WEBSERVICES_RPC_SERVER_HOST
ILIAS_WEBSERVICES_RPC_SERVER_PORT="${ILIAS_WEBSERVICES_RPC_SERVER_PORT:=11111}" && export ILIAS_WEBSERVICES_RPC_SERVER_PORT

ILIAS_CHATROOM_ADDRESS="${ILIAS_CHATROOM_ADDRESS:=0.0.0.0}" && export ILIAS_CHATROOM_ADDRESS
ILIAS_CHATROOM_PORT="${ILIAS_CHATROOM_PORT:=8080}" && export ILIAS_CHATROOM_PORT
ILIAS_CHATROOM_LOG="${ILIAS_CHATROOM_LOG:=/dev/stdout}" && export ILIAS_CHATROOM_LOG
ILIAS_CHATROOM_LOG_LEVEL="${ILIAS_CHATROOM_LOG_LEVEL:=info}" && export ILIAS_CHATROOM_LOG_LEVEL
ILIAS_CHATROOM_ERROR_LOG="${ILIAS_CHATROOM_ERROR_LOG:=/dev/stderr}" && export ILIAS_CHATROOM_ERROR_LOG

ILIAS_ROOT_USER_LOGIN="${ILIAS_ROOT_USER_LOGIN:=root}"
ILIAS_CRON_USER_LOGIN="${ILIAS_CRON_USER_LOGIN:=cron}"

ILIAS_CRON_PERIOD="${ILIAS_CRON_PERIOD:=*/5 * * * *}"

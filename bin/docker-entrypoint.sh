#!/usr/bin/env sh

set -e

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

if [ ! -f "$ILIAS_WEB_DIR/ilias.php" ]; then
    echo "Please provide ILIAS source code to $ILIAS_WEB_DIR"
    exit 1
fi

ensureWwwData "$ILIAS_FILESYSTEM_DATA_DIR"
ensureWwwData "$ILIAS_FILESYSTEM_WEB_DATA_DIR"
ensureWwwData "$ILIAS_LOG_DIR"

ilias_version_number=`/flux-ilias-ilias-base/bin/get_ilias_version_number.php`
echo "Your ILIAS version number is $ilias_version_number"

if [ `versionIsGreaterOrEqual "$ilias_version_number" 6.0` = "false" ]; then
    echo "ILIAS 5.4 or lower detected"
    echo "You need at least ILIAS 6"
    echo "Older ILIAS versions are not supported anymore"
    echo "Because it does not support setup cli"
    exit 1
fi

auto_skip_config_temp_file=/tmp/auto_skip_config_temp_file
if [ -f "$auto_skip_config_temp_file" ]; then
    echo "Auto skip config (This is not a new container (re)creation)"
else
    echo "Run config"

    if [ `versionIsGreaterOrEqual "$ilias_version_number" 7.0` = "true" ]; then
        is_ilias_7_or_higher="true"
        echo "ILIAS 7 or higher detected"
    else
        is_ilias_7_or_higher="false"
        echo "ILIAS 6 detected"
    fi

    if [ -z "$ILIAS_DATABASE_TYPE" ] || [ "$ILIAS_DATABASE_TYPE" = "mysql" ] || [ "$ILIAS_DATABASE_TYPE" = "innodb" ]; then
        is_mysql_like_database="true"
        echo "MySQL-like database detected"
    else
        is_mysql_like_database="false"
        echo "Non-MySQL-like database detected"
    fi

    if [ -d "$ILIAS_FILESYSTEM_WEB_DATA_DIR/$ILIAS_COMMON_CLIENT_ID/usr_images" ]; then
        is_ilias_installed="true"
        echo "Already installed ILIAS detected"
    else
        is_ilias_installed="false"
        echo "New ILIAS installation detected"
    fi

    if [ -z "$ILIAS_HTTP_PATH" ]; then
        if [ -n "$ILIAS_NGINX_HTTPS_CERT" ]; then
            if [ -n "$ILIAS_NGINX_HTTPS_PORT" ] && [ "$ILIAS_NGINX_HTTPS_PORT" != "443" ]; then
                ILIAS_HTTP_PATH=https://$(hostname):$ILIAS_NGINX_HTTPS_PORT
            else
                ILIAS_HTTP_PATH=https://$(hostname)
            fi
        else
            if [ -n "$ILIAS_NGINX_HTTP_PORT" ] && [ "$ILIAS_NGINX_HTTP_PORT" != "80" ]; then
                ILIAS_HTTP_PATH=http://$(hostname):$ILIAS_NGINX_HTTP_PORT
            else
                ILIAS_HTTP_PATH=http://$(hostname)
            fi
        fi
        export ILIAS_HTTP_PATH
        echo "Auto set empty ILIAS_HTTP_PATH to $ILIAS_HTTP_PATH (May not work)"
    fi

    if [ -z "$ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL" ]; then
        if [ -n "$ILIAS_CHATROOM_HTTPS_CERT" ]; then
            ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL=https://chatroom:$ILIAS_CHATROOM_PORT
        else
            ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL=http://chatroom:$ILIAS_CHATROOM_PORT
        fi
        export ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL
        echo "Auto set empty ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL to $ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL"
    fi

    if [ -z "$ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL" ]; then
        if [ -n "$ILIAS_CHATROOM_HTTPS_CERT" ]; then
            ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL=https$(echo "$ILIAS_HTTP_PATH" | sed 's/^https\?//'):$ILIAS_CHATROOM_PORT
        else
            ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL=http$(echo "$ILIAS_HTTP_PATH" | sed 's/^https\?//'):$ILIAS_CHATROOM_PORT
        fi
        export ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL
        echo "Auto set empty ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL to $ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL"
    fi

    echo "Generate php config"
    echo "[www]
listen = $ILIAS_PHP_LISTEN:$ILIAS_PHP_PORT" > "$PHP_INI_DIR/../php-fpm.d/zz_ilias.conf"
    echo "display_errors = $ILIAS_PHP_DISPLAY_ERRORS
error_reporting = $ILIAS_PHP_ERROR_REPORTING
expose_php = $ILIAS_PHP_EXPOSE
log_errors = $ILIAS_PHP_LOG_ERRORS
max_execution_time = $ILIAS_PHP_MAX_EXECUTION_TIME
max_input_time = $ILIAS_PHP_MAX_INPUT_TIME
max_input_vars = $ILIAS_PHP_MAX_INPUT_VARS
memory_limit = $ILIAS_PHP_MEMORY_LIMIT
post_max_size = $ILIAS_PHP_POST_MAX_SIZE
upload_max_filesize = $ILIAS_PHP_UPLOAD_MAX_SIZE" > "$PHP_INI_DIR/conf.d/ilias.ini"

    if [ "$ILIAS_WEB_DIR_COMPOSER_AUTO_INSTALL" = "true" ]; then
        echo "Install composer dependencies"

        composer install -d "$ILIAS_WEB_DIR" --no-dev

        host_owner="$(stat -c %u "$ILIAS_WEB_DIR")":"$(stat -c %g "$ILIAS_WEB_DIR")"
        echo "Ensure the owner of composer files is $host_owner (Like other ILIAS source code)"
        chown "$host_owner" -R "$ILIAS_WEB_DIR/libs/composer/vendor"
        chown "$host_owner" "$ILIAS_WEB_DIR/composer.json"
        chown "$host_owner" "$ILIAS_WEB_DIR/composer.lock"
    fi

    ensureSymlink "$ILIAS_FILESYSTEM_WEB_DATA_DIR" "$_ILIAS_WEB_DATA_DIR"
    ensureSymlink "$ILIAS_FILESYSTEM_INI_PHP_FILE" "$_ILIAS_WEB_PHP_FILE"

    if [ "$is_mysql_like_database" = "true" ]; then
        mysql_query="mysql --host=$ILIAS_DATABASE_HOST --port=$ILIAS_DATABASE_PORT --user=$ILIAS_DATABASE_USER --password=$(getFileEnv ILIAS_DATABASE_PASSWORD) $ILIAS_DATABASE_DATABASE -e"
        until $mysql_query "SELECT VERSION()" 1>/dev/null; do
            echo "Waiting 3 seconds for ensure database is ready"
            sleep 3
        done
        echo "Database is ready"
    else
        echo "WARNING: Waiting for ensure database is ready only works with mysql like database"
        echo "Further config may will fail"
    fi

    echo "(Re)generate ILIAS setup cli $ILIAS_CONFIG_FILE"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/generate_ilias_config.php

    can_write_to_www=`checkWwwData "$ILIAS_WEB_DIR"`
    if [ "$can_write_to_www" = "false" ]; then
        echo "www-data can not write to $ILIAS_WEB_DIR"
        echo "Temporary patch ILIAS setup for allow run with www-data without needed $ILIAS_WEB_DIR write permissions"
        if [ "$is_ilias_7_or_higher" = "true" ]; then
            sed -i "s/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/\/\/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
        else
            sed -i "s/new Setup\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/\/\/new Setup\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
        fi
    fi

    if [ "$is_ilias_7_or_higher" = "false" ]; then
        echo "Temporary disable apcu ext because ILIAS 6 setup is broken with it"
        mv "$PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini" "$PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini.disabled"
    fi

    if [ "$is_ilias_installed" = "true" ]; then
        echo "Call ILIAS update setup cli"
        if [ "$is_ilias_7_or_higher" = "true" ]; then
            echo "Note: Auto plugin setup will be disabled because some are broken with it"
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh update --yes --no-plugins "$ILIAS_CONFIG_FILE"
        else
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh update --yes "$ILIAS_CONFIG_FILE"
        fi
    else
        echo "Call ILIAS install setup cli"
        if [ "$is_ilias_7_or_higher" = "true" ]; then
            echo "Note: Auto plugin setup will be disabled because some are broken with it"
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh install --yes --no-plugins "$ILIAS_CONFIG_FILE"
        else
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh install --yes "$ILIAS_CONFIG_FILE"
        fi
    fi

    if [ "$can_write_to_www" = "false" ]; then
        echo "Remove ILIAS setup patch"
        if [ "$is_ilias_7_or_higher" = "true" ]; then
            sed -i "s/\/\/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
        else
            sed -i "s/\/\/new Setup\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/new Setup\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
        fi
    fi

    if [ "$is_ilias_7_or_higher" = "false" ]; then
        echo "Re-enable apcu ext"
        mv "$PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini.disabled" "$PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini"
    fi

    if [ "$is_mysql_like_database" = "true" ]; then
        echo "Set ILIAS $ILIAS_ROOT_USER_LOGIN user password"
        $mysql_query "UPDATE usr_data SET passwd='`hashPassword "$(getFileEnv ILIAS_ROOT_USER_PASSWORD)"`',passwd_enc_type='md5' WHERE login='$ILIAS_ROOT_USER_LOGIN'"
    else
        echo "WARNING: Set ILIAS $ILIAS_ROOT_USER_LOGIN user password only works with mysql like database"
        echo "Further config may will fail"
    fi

    if [ "$ILIAS_DEVMODE" = "true" ]; then
        echo "Enable ILIAS development mode"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_client_ini_setting.php system DEVMODE 1
    else
        echo "Disable ILIAS development mode"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_client_ini_setting.php system DEVMODE 0
    fi

    if [ -n "$(getFileEnv ILIAS_CRON_USER_PASSWORD)" ]; then
        echo "Ensure ILIAS $ILIAS_CRON_USER_LOGIN user exists"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/ensure_ilias_user_exists.php "$ILIAS_CRON_USER_LOGIN" "$(getFileEnv ILIAS_CRON_USER_PASSWORD)"
    fi

    if [ "$is_ilias_7_or_higher" = "false" ]; then
        echo "Manually set common master password for ILIAS 6"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_ini_setting.php setup pass "`hashPassword "$(getFileEnv ILIAS_COMMON_MASTER_PASSWORD)"`"

        echo "Manually set ilserver server for ILIAS 6"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common rpc_server_host "$ILIAS_WEBSERVICES_RPC_SERVER_HOST"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common rpc_server_port "$ILIAS_WEBSERVICES_RPC_SERVER_PORT"

        echo "Manually set chatroom server for ILIAS 6"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php address "$ILIAS_CHATROOM_ADDRESS"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php port "$ILIAS_CHATROOM_PORT"
        if [ -n "$ILIAS_CHATROOM_HTTPS_CERT" ]; then
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php protocol https
        else
            su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php protocol http
        fi
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php cert "$ILIAS_CHATROOM_HTTPS_CERT"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php key "$ILIAS_CHATROOM_HTTPS_KEY"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php dhparam "$ILIAS_CHATROOM_HTTPS_DHPARAM"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php log "$ILIAS_CHATROOM_LOG"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php log_level "$ILIAS_CHATROOM_LOG_LEVEL"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php error_log "$ILIAS_CHATROOM_ERROR_LOG"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php ilias_proxy 1
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php ilias_url "$ILIAS_CHATROOM_ILIAS_PROXY_ILIAS_URL"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php client_proxy 1
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_chatroom_setting.php client_url "$ILIAS_CHATROOM_CLIENT_PROXY_CLIENT_URL"
    fi

    if [ "$ILIAS_LUCENE_SEARCH" = "true" ]; then
        echo "Enable lucene search"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common search_lucene 1
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/enable_or_disable_ilias_cron_job.php src_lucene_indexer 1
    else
        echo "Disable lucene search"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common search_lucene 0
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/enable_or_disable_ilias_cron_job.php src_lucene_indexer 0
    fi

    echo "Set smtp server"
    if [ -n "$ILIAS_SMTP_HOST" ]; then
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_status 1
    else
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_status 0
    fi
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_host "$ILIAS_SMTP_HOST"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_port "$ILIAS_SMTP_PORT"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_encryption "$ILIAS_SMTP_ENCRYPTION"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_user "$(getFileEnv ILIAS_SMTP_USER)"
    su-exec www-data:www-data /flux-ilias-ilias-base/bin/set_ilias_general_setting.php common mail_smtp_password "$(getFileEnv ILIAS_SMTP_PASSWORD)"

    echo "Config finished"
    echo "Skip it until a new container (re)creation"
    touch "$auto_skip_config_temp_file"
fi

echo "Start php-fpm"
exec /usr/local/bin/docker-php-entrypoint php-fpm

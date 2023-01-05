#!/usr/bin/env sh

set -e

. /flux-ilias-ilias-base/src/functions.sh

checkIliasSourceCode

checkIliasVersionNumber

ensureWwwData "$ILIAS_FILESYSTEM_DATA_DIR"
ensureWwwData "$ILIAS_FILESYSTEM_WEB_DATA_DIR"
ensureWwwData "$ILIAS_LOG_DIR"

if [ "$ILIAS_STYLE_MANAGE_SYSTEM_STYLES" = "true" ]; then
    ensureWwwData "$ILIAS_WEB_DIR/Customizing/global/skin"
fi

auto_skip_config_temp_file=/tmp/auto_skip_config_temp_file
if [ -f "$auto_skip_config_temp_file" ]; then
    echo "Auto skip config (This is not a new container (re)creation)"
else
    echo "Run config"

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
        sed -i "s/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/\/\/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
    fi

    if [ "$is_ilias_installed" = "true" ]; then
        echo "Call ILIAS update setup cli"
        echo "Note: Auto plugin setup will be disabled because some are broken with it"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh update --yes --no-plugins "$ILIAS_CONFIG_FILE"
    else
        echo "Call ILIAS install setup cli"
        echo "Note: Auto plugin setup will be disabled because some are broken with it"
        su-exec www-data:www-data /flux-ilias-ilias-base/bin/run_ilias_cli.sh install --yes --no-plugins "$ILIAS_CONFIG_FILE"
    fi

    if [ "$can_write_to_www" = "false" ]; then
        echo "Remove ILIAS setup patch"
        sed -i "s/\/\/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/new Setup\\\\Condition\\\\CanCreateFilesInDirectoryCondition(dirname(__DIR__, 2))/" "$ILIAS_WEB_DIR/setup/classes/class.ilIniFilesPopulatedObjective.php"
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

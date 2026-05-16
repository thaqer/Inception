#!/bin/bash
set -euo pipefail

read_secret() {
    local var_name="$1"
    local file_var_name="${var_name}_FILE"
    local value="${!var_name:-}"
    local file_value="${!file_var_name:-}"

    if [[ -n "$value" && -n "$file_value" ]]; then
        echo "Error: both $var_name and $file_var_name are set" >&2
        exit 1
    fi

    if [[ -n "$file_value" ]]; then
        if [[ ! -f "$file_value" ]]; then
            echo "Error: secret file '$file_value' does not exist" >&2
            exit 1
        fi
        value="$(< "$file_value")"
        export "$var_name=$value"
    fi

    if [[ -z "${!var_name:-}" ]]; then
        echo "Error: required variable $var_name is not set" >&2
        exit 1
    fi
}

read_secret MYSQL_PASSWORD
read_secret WP_ADMIN_PASSWORD
read_secret WP_USER_PASSWORD

: "${MYSQL_DATABASE:?Error: MYSQL_DATABASE is required}"
: "${MYSQL_USER:?Error: MYSQL_USER is required}"
: "${MYSQL_HOST:?Error: MYSQL_HOST is required}"
: "${MYSQL_PORT:?Error: MYSQL_PORT is required}"
: "${WP_TITLE:?Error: WP_TITLE is required}"
: "${WP_URL:?Error: WP_URL is required}"
: "${WP_ADMIN_USER:?Error: WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?Error: WP_ADMIN_EMAIL is required}"
: "${WP_USER:?Error: WP_USER is required}"
: "${WP_USER_EMAIL:?Error: WP_USER_EMAIL is required}"

if echo "$WP_ADMIN_USER" | grep -Eiq 'admin|administrator'; then
    echo "Error: WP_ADMIN_USER cannot contain 'admin' or 'administrator'" >&2
    exit 1
fi

mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html

for _ in {1..60}; do
    if mysqladmin ping -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

if ! mysqladmin ping -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; then
    echo "Error: MariaDB is not reachable from WordPress" >&2
    exit 1
fi

if [[ ! -f /var/www/html/wp-includes/version.php ]]; then
    wp core download --allow-root --path=/var/www/html
fi

if [[ ! -f /var/www/html/wp-config.php ]]; then
    wp config create \
        --allow-root \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOST:$MYSQL_PORT"
fi

if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
fi

if ! wp user get "$WP_USER" --allow-root --path=/var/www/html >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --allow-root \
        --path=/var/www/html \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"
fi

chown -R www-data:www-data /var/www/html

exec "$@"

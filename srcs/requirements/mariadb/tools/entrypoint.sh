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

validate_identifier() {
    local label="$1"
    local value="$2"
    if [[ ! "$value" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "Error: $label must match [A-Za-z0-9_]+" >&2
        exit 1
    fi
}

read_secret MYSQL_ROOT_PASSWORD
read_secret MYSQL_PASSWORD

: "${MYSQL_DATABASE:?Error: MYSQL_DATABASE is required}"
: "${MYSQL_USER:?Error: MYSQL_USER is required}"

validate_identifier "MYSQL_DATABASE" "$MYSQL_DATABASE"
validate_identifier "MYSQL_USER" "$MYSQL_USER"

# mysql/mariadb clients read MYSQL_HOST from env; force socket usage for local bootstrap commands.
unset MYSQL_HOST MYSQL_PORT MYSQL_TCP_PORT

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [[ ! -d /var/lib/mysql/mysql ]]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

    mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
    pid="$!"

    for _ in {1..30}; do
        if mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    if ! mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent >/dev/null 2>&1; then
        echo "Error: MariaDB bootstrap failed to start" >&2
        kill "$pid" >/dev/null 2>&1 || true
        exit 1
    fi

    mysql --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
SQL

    mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -uroot -p"$MYSQL_ROOT_PASSWORD" shutdown
fi

exec "$@"

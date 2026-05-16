#!/bin/bash
set -euo pipefail

: "${DOMAIN_NAME:?Error: DOMAIN_NAME is required}"

mkdir -p /etc/nginx/ssl

if [[ ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.crt" || ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.key" ]]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "/etc/nginx/ssl/${DOMAIN_NAME}.key" \
        -out "/etc/nginx/ssl/${DOMAIN_NAME}.crt" \
        -subj "/C=MA/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}" >/dev/null 2>&1
fi

envsubst '$DOMAIN_NAME' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

exec "$@"

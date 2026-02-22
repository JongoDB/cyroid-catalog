#!/bin/bash
set -e

: "${DOMAIN:=weather-server}"
USE_TLS="${USE_TLS:-false}"
SSL_CERT_NAME="${SSL_CERT_NAME:-${DOMAIN}.crt}"
SSL_KEY_NAME="${SSL_KEY_NAME:-${DOMAIN}.key}"
CERT_DIR="/etc/nginx/certs"

export DOMAIN SSL_CERT_NAME SSL_KEY_NAME

echo "=== Weather Frontend + Nginx Reverse Proxy ==="
echo "  Domain:           ${DOMAIN}"
echo "  TLS:              ${USE_TLS}"
echo "  Weather app port: ${WEATHER_APP_PORT:-5000}"
echo "  Nginx port:       ${NGINX_HTTP_PORT:-80}"
echo "  C2 proxy target:  ${SLIVER_C2_HOST:-10.10.2.30}:${SLIVER_HTTP_PORT:-8080}"
echo "  C2 path:          ${SLIVER_C2_PATH:-/api/news/}"
echo ""

TEMPLATE="/etc/nginx/nginx.conf.template"

if [ "${USE_TLS}" = "true" ]; then
    mkdir -p "${CERT_DIR}"
    CRT="${CERT_DIR}/${SSL_CERT_NAME}"
    KEY="${CERT_DIR}/${SSL_KEY_NAME}"

    if [ ! -f "${CRT}" ] || [ ! -f "${KEY}" ]; then
        echo "[entrypoint] No certs found. Generating self-signed cert for ${DOMAIN}..."
        cat > /tmp/openssl.cnf <<EOF
[req]
distinguished_name=req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${DOMAIN}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
EOF
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "${KEY}" -out "${CRT}" -config /tmp/openssl.cnf >/dev/null 2>&1
        chmod 600 "${KEY}"
        echo "[entrypoint] Self-signed cert created."
    else
        echo "[entrypoint] Using existing certs."
    fi

    TEMPLATE="/etc/nginx/nginx.tls.conf.template"
    echo "[entrypoint] TLS enabled; using HTTPS template."
else
    echo "[entrypoint] TLS disabled; using HTTP template."
fi

# Render nginx config template with environment variables
envsubst '${DOMAIN} ${SSL_CERT_NAME} ${SSL_KEY_NAME} ${SLIVER_C2_HOST} ${SLIVER_HTTP_PORT} ${SLIVER_C2_PATH} ${NGINX_HTTP_PORT} ${WEATHER_APP_PORT}' \
    < "${TEMPLATE}" \
    > /etc/nginx/nginx.conf

echo "[entrypoint] Nginx config rendered."
nginx -t

# Start all services via supervisord
exec "$@"

#!/bin/bash
set -e

echo "=== Weather Frontend + Nginx Reverse Proxy ==="
echo "  Weather app port: ${WEATHER_APP_PORT:-5000}"
echo "  Nginx port:       ${NGINX_HTTP_PORT:-80}"
echo "  C2 proxy target:  ${SLIVER_C2_HOST:-10.10.2.30}:${SLIVER_HTTP_PORT:-8080}"
echo "  C2 path:          ${SLIVER_C2_PATH:-/api/news/}"
echo ""

# Render nginx config template with environment variables
envsubst '${DOMAIN} ${SLIVER_C2_HOST} ${SLIVER_HTTP_PORT} ${SLIVER_C2_PATH} ${NGINX_HTTP_PORT} ${WEATHER_APP_PORT}' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

echo "Nginx config rendered."

# Start all services via supervisord
exec "$@"

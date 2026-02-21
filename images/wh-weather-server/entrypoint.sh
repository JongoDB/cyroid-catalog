#!/bin/bash
set -e

# Render nginx config template with environment variables
envsubst '${WEATHER_APP_PORT} ${SLIVER_C2_HOST} ${SLIVER_HTTP_PORT} ${NGINX_HTTP_PORT} ${SLIVER_C2_PATH}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "=== Watering Hole - Weather Server ==="
echo "Nginx listening on port ${NGINX_HTTP_PORT}"
echo "Weather app on port ${WEATHER_APP_PORT}"
echo "C2 proxy: ${SLIVER_C2_PATH} -> ${SLIVER_C2_HOST}:${SLIVER_HTTP_PORT}"
echo "======================================="

exec "$@"

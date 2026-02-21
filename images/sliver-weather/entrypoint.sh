#!/bin/bash
set -e

echo "=== Sliver Weather Listening Post ==="
echo "Starting services..."

# Initialize sliver server configs if first run
if [ ! -d "/root/.sliver" ]; then
    echo "Initializing Sliver server..."
    /usr/local/bin/sliver-server unpack --force 2>/dev/null || true
fi

# Generate operator config for remote C2 management (blue-space)
# The operator on the Ubuntu C2 machine will use this config
if [ ! -f "/opt/sliver-weather/operator-configs/operator_config.cfg" ]; then
    mkdir -p /opt/sliver-weather/operator-configs
    echo "Generating operator config (use from C2 operator machine)..."
    /usr/local/bin/sliver-server operator \
        --name operator \
        --lhost 0.0.0.0 \
        --save /opt/sliver-weather/operator-configs/operator_config.cfg \
        2>/dev/null || echo "Operator config will be generated after first daemon start"
fi

echo ""
echo "  Watering hole website:  http://<dmz-ip>/ or https://<dmz-ip>/"
echo "  Sliver mTLS listener:   <dmz-ip>:31337"
echo "  Sliver operator gRPC:   <blue-space-ip>:31338"
echo ""
echo "  Operator config: /opt/sliver-weather/operator-configs/"
echo ""

# Start all services via supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

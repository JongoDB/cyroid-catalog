#!/bin/bash
set -e

# Configure routing through lab gateway (.1) instead of Docker bridge
configure_routing() {
    local ip
    ip=$(hostname -I | awk '{print $1}')
    local gateway
    gateway=$(echo "$ip" | sed 's/\.[0-9]*$/.1/')
    if ! ip route show default | grep -q "via $gateway"; then
        ip route del default 2>/dev/null || true
        ip route add default via "$gateway" 2>/dev/null || true
    fi
}
configure_routing

echo "=== CYROID ICS PLC Simulator ==="
echo "Name:     ${PLC_NAME}"
echo "Role:     ${PLC_ROLE}"
echo "Protocol: ${PLC_PROTOCOL}"
echo "IP:       $(hostname -I | awk '{print $1}')"
echo "================================"

exec "$@"

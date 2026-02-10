#!/bin/bash
set -e

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

echo "=== CYROID ICS SCADA HMI ==="
echo "Name: ${HMI_NAME}"
echo "Role: ${HMI_ROLE}"
echo "Web:  http://$(hostname -I | awk '{print $1}'):8080"
echo "============================="

exec "$@"

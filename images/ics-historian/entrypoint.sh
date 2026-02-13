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

    # IT/OT DMZ hosts need routes to OT networks via the OT firewall.
    # The enterprise firewall at .1 doesn't route to OT subnets.
    local subnet
    subnet=$(echo "$ip" | cut -d. -f1-3)
    if [ "$subnet" = "172.16.2" ]; then
        local ot_gw="${subnet}.253"
        for net in 172.16.3.0/24 172.16.4.0/24 172.16.5.0/24; do
            ip route add "$net" via "$ot_gw" 2>/dev/null || true
        done
    fi
}
configure_routing

echo "=== CYROID ICS Historian ==="
echo "Web:  http://$(hostname -I | awk '{print $1}'):8080"
echo "Poll: every ${POLL_INTERVAL}s"
echo "============================"

exec "$@"

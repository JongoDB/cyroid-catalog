#!/bin/sh
# Configure network routing through the firewall gateway (.1)
# Docker assigns .254 as the default gateway (Docker bridge), but in the
# CYROID lab environment, traffic must route through the firewall container
# at .1 for proper inter-segment connectivity (e.g., reverse shells).
ip=$(hostname -I | awk '{print $1}')
if [ -n "$ip" ]; then
    gateway=$(echo "$ip" | sed 's/\.[0-9]*$/.1/')
    if ! ip route show default | grep -q "via $gateway"; then
        ip route del default 2>/dev/null || true
        ip route add default via "$gateway" 2>/dev/null || true
    fi
fi

exec python app.py

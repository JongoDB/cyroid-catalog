#!/bin/bash
set -e

echo "=== CYROID ICS OT Zone Firewall ==="
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Wait for interfaces to stabilize
sleep 2

echo "Applying OT firewall rules..."
/usr/local/bin/ot-firewall-rules.sh

echo ""
echo "=== Network Interfaces ==="
ip -4 addr show | grep -E "inet |^[0-9]"
echo ""
echo "=== Active Firewall Rules ==="
iptables -L FORWARD -n --line-numbers 2>/dev/null | head -30
echo "============================="

exec "$@"

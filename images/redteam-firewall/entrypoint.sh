#!/bin/bash
# CYROID Red Team Firewall Entrypoint
# Enables IP forwarding and applies firewall rules

set -e

echo "[*] CYROID Red Team Firewall starting..."

# Enable IP forwarding
echo "[*] Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding

# Wait for network interfaces to be ready
echo "[*] Waiting for network interfaces..."
sleep 2

# Show network configuration
echo "[*] Network interfaces:"
ip addr show

# Apply firewall rules
echo "[*] Applying firewall rules..."
/usr/local/bin/firewall-rules.sh

echo "[*] Firewall ready!"
echo "[*] NAT mappings:"
echo "    172.16.0.100:80   -> 172.16.1.10:80  (webserver)"
echo "    172.16.0.100:443  -> 172.16.1.10:443 (webserver)"
echo "    172.16.0.100:8080 -> 172.16.1.40:8080 (jenkins)"
echo ""

# Execute the command (default: tail -f /dev/null to keep container running)
exec "$@"

#!/bin/bash
# CYROID Red Team Lab - VPN Entrypoint

set -e

echo "[*] CYROID VPN Gateway starting..."

# Create TUN device if needed
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi
chmod 600 /dev/net/tun

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set up NAT for VPN clients to reach internal network
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth1 -j MASQUERADE
iptables -A FORWARD -i tun0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "[*] VPN ready!"
echo "[*] Clients can connect on UDP 1194"
echo "[*] Valid users: vpnuser, jsmith, mwilliams"
echo ""

exec "$@"

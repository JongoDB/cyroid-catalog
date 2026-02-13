#!/bin/bash
# CYROID Red Team Lab - Firewall Rules
# Configures NAT and inter-segment access control
#
# Network Layout:
# - Internet: 172.16.0.0/24 (eth0, gateway .1)
# - DMZ:      172.16.1.0/24 (eth1, gateway .1)
# - Internal: 172.16.2.0/24 (eth2, gateway .1)

# Network definitions (overridable via environment variables)
INTERNET_NET="${FW_INTERNET_NET:-172.16.0.0/24}"
DMZ_NET="${FW_DMZ_NET:-172.16.1.0/24}"
INTERNAL_NET="${FW_INTERNAL_NET:-172.16.2.0/24}"

# Virtual IP for NAT'd services (on internet network)
NAT_IP="${FW_NAT_IP:-172.16.0.100}"

# DMZ hosts
WEBSERVER="${FW_WEBSERVER:-172.16.1.10}"
JUMPBOX="${FW_JUMPBOX:-172.16.1.20}"
FTP="${FW_FTP:-172.16.1.30}"
APP_SERVER="${FW_APP_SERVER:-172.16.1.40}"
APP_SERVER_PORT="${FW_APP_SERVER_PORT:-8080}"

# Internal hosts
FILESERVER="${FW_FILESERVER:-172.16.2.10}"
DC01="${FW_DC01:-172.16.2.12}"
DB01="${FW_DB01:-172.16.2.40}"

# ============================================================================
# FLUSH EXISTING RULES
# ============================================================================
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# ============================================================================
# DEFAULT POLICIES
# ============================================================================
# Default deny for FORWARD, allow INPUT/OUTPUT for management
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# ============================================================================
# NAT RULES - Internet to DMZ Services
# ============================================================================

# Add the virtual IP to the internet interface
ip addr add ${NAT_IP}/24 dev eth0 2>/dev/null || true

# DNAT: Forward incoming connections to DMZ services
# Webserver HTTP
iptables -t nat -A PREROUTING -d ${NAT_IP} -p tcp --dport 80 \
    -j DNAT --to-destination ${WEBSERVER}:80

# Webserver HTTPS
iptables -t nat -A PREROUTING -d ${NAT_IP} -p tcp --dport 443 \
    -j DNAT --to-destination ${WEBSERVER}:443

# Webserver SSH (intentional exposure for training -- allows credential-based access)
iptables -t nat -A PREROUTING -d ${NAT_IP} -p tcp --dport 22 \
    -j DNAT --to-destination ${WEBSERVER}:22

# App server (Jenkins, WordPress, etc. depending on blueprint)
iptables -t nat -A PREROUTING -d ${NAT_IP} -p tcp --dport 8080 \
    -j DNAT --to-destination ${APP_SERVER}:${APP_SERVER_PORT}

# SNAT: Masquerade return traffic from DMZ to internet
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# SNAT: Masquerade DNAT'd traffic entering DMZ so responses route back
# through the firewall (without this, DMZ hosts send responses via Docker
# bridge, bypassing the firewall's reverse-NAT)
iptables -t nat -A POSTROUTING -o eth1 -s ${INTERNET_NET} -j MASQUERADE

# ============================================================================
# FORWARD RULES - Allow NAT'd traffic
# ============================================================================

# Allow established/related connections (return traffic)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Internet → DMZ (NAT'd services only)
iptables -A FORWARD -s ${INTERNET_NET} -d ${WEBSERVER} -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s ${INTERNET_NET} -d ${WEBSERVER} -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s ${INTERNET_NET} -d ${WEBSERVER} -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s ${INTERNET_NET} -d ${APP_SERVER} -p tcp --dport ${APP_SERVER_PORT} -j ACCEPT

# ============================================================================
# DMZ → Internal (Limited access for legitimate services)
# ============================================================================

# Jumpbox can SSH to any internal host (admin access)
iptables -A FORWARD -s ${JUMPBOX} -d ${INTERNAL_NET} -p tcp --dport 22 -j ACCEPT

# App server can SSH to internal hosts (lateral movement path for training)
iptables -A FORWARD -s ${APP_SERVER} -d ${INTERNAL_NET} -p tcp --dport 22 -j ACCEPT

# Webserver can reach database (application requirement)
iptables -A FORWARD -s ${WEBSERVER} -d ${DB01} -p tcp --dport 3306 -j ACCEPT

# App server can reach fileserver SMB (deploy artifacts)
iptables -A FORWARD -s ${APP_SERVER} -d ${FILESERVER} -p tcp --dport 445 -j ACCEPT

# ============================================================================
# Internal → DMZ (Admin access to jumpbox)
# ============================================================================

# Internal hosts can SSH to jumpbox
iptables -A FORWARD -s ${INTERNAL_NET} -d ${JUMPBOX} -p tcp --dport 22 -j ACCEPT

# ============================================================================
# DMZ → Internet (Outbound - intentional misconfiguration for training)
# ============================================================================
# In many real environments, DMZ servers can initiate outbound connections.
# This allows reverse shells back to the attacker - a common attack vector.
iptables -A FORWARD -s ${DMZ_NET} -d ${INTERNET_NET} -j ACCEPT

# ============================================================================
# DMZ ↔ DMZ (Allow within segment)
# ============================================================================
iptables -A FORWARD -s ${DMZ_NET} -d ${DMZ_NET} -j ACCEPT

# ============================================================================
# Internal ↔ Internal (Allow within segment)
# ============================================================================
iptables -A FORWARD -s ${INTERNAL_NET} -d ${INTERNAL_NET} -j ACCEPT

# ============================================================================
# EXTRA FORWARD RULES (blueprint-specific overrides)
# ============================================================================
# FW_EXTRA_FORWARD: comma-separated rules in "src:dst:port" format
# Example: FW_EXTRA_FORWARD="172.16.0.0/24:172.16.1.10:389,172.16.0.0/24:172.16.1.10:636"
if [ -n "${FW_EXTRA_FORWARD:-}" ]; then
    IFS=',' read -ra EXTRA_RULES <<< "${FW_EXTRA_FORWARD}"
    for rule in "${EXTRA_RULES[@]}"; do
        IFS=':' read -r src dst port <<< "$rule"
        if [ -n "$src" ] && [ -n "$dst" ] && [ -n "$port" ]; then
            iptables -A FORWARD -s "$src" -d "$dst" -p tcp --dport "$port" -j ACCEPT
        fi
    done
fi

# ============================================================================
# ICMP (Allow ping for recon/debugging)
# ============================================================================
iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

# ============================================================================
# LOGGING (Optional - for debugging)
# ============================================================================
# Uncomment to log dropped packets
# iptables -A FORWARD -j LOG --log-prefix "FW-DROP: " --log-level 4

# ============================================================================
# Show rules summary
# ============================================================================
echo "[*] Firewall rules applied:"
echo "    Forward rules:"
iptables -L FORWARD -n -v --line-numbers | head -20
echo ""
echo "    NAT rules:"
iptables -t nat -L -n -v | grep -A 5 "PREROUTING\|POSTROUTING"

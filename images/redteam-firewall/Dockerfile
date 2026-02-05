# CYROID Red Team Lab - Firewall/Router
# Multi-homed gateway with NAT and iptables firewall rules
#
# Network Interfaces (configured by CYROID):
# - eth0: Internet (172.16.0.1)
# - eth1: DMZ (172.16.1.1)
# - eth2: Internal (172.16.2.1)
#
# NAT Rules:
# - 172.16.0.100:80 → 172.16.1.10:80 (webserver)
# - 172.16.0.100:443 → 172.16.1.10:443 (webserver)
# - 172.16.0.100:8080 → 172.16.1.40:8080 (jenkins)
#
# Build: docker build -t cyroid/redteam-firewall:latest .
# Run: docker run -d --cap-add=NET_ADMIN --cap-add=NET_RAW cyroid/redteam-firewall:latest

FROM alpine:3.19

# Install networking tools
RUN apk add --no-cache \
    iptables \
    ip6tables \
    iproute2 \
    tcpdump \
    net-tools \
    bind-tools \
    bash \
    curl \
    && mkdir -p /etc/iptables

# Copy firewall configuration script
COPY firewall-rules.sh /usr/local/bin/firewall-rules.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/firewall-rules.sh /entrypoint.sh

# Enable IP forwarding at runtime via entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

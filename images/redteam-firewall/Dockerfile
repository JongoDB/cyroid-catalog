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
# Size: ~15MB

FROM alpine:3.19

# Firewall rules are configurable via environment variables.
# Defaults match Red Team Training Lab v3 (Jenkins at .40:8080).
# Override FW_APP_SERVER_PORT=80 for blueprints with WordPress at .40.
ENV FW_APP_SERVER_PORT=8080

COPY firewall-rules.sh /usr/local/bin/
COPY entrypoint.sh /

RUN apk add --no-cache \
        iptables \
        iproute2 \
        bash \
    && chmod +x /usr/local/bin/firewall-rules.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

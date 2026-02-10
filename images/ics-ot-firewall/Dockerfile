# CYROID ICS OT Zone Firewall
# Enforces Purdue Model segmentation with ICS-aware firewall rules
#
# Network Interfaces (configured by CYROID):
# - eth0: IT/OT DMZ (172.16.2.0/24)
# - eth1: Operations (172.16.3.0/24)
# - eth2: Supervisory/HMI (172.16.4.0/24)
# - eth3: Process Control (172.16.5.0/24)
#
# Build: docker build -t cyroid/ics-ot-firewall:latest .

FROM alpine:3.19

COPY ot-firewall-rules.sh /usr/local/bin/
COPY entrypoint.sh /

RUN apk add --no-cache \
        iptables \
        iproute2 \
        bash \
    && chmod +x /usr/local/bin/ot-firewall-rules.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

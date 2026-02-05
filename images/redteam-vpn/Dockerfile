# CYROID Red Team Lab - VPN Gateway (OpenVPN)
# Dual-homed VPN server for alternative attack path
#
# Network Interfaces:
# - eth0: Internet (172.16.0.50) - client connections
# - eth1: Internal (172.16.2.50) - tunnel endpoint
#
# Credentials (PAM auth against local users):
# - vpnuser:VPN2024!
# - jsmith:Summer2024
# - mwilliams:Welcome123
#
# Build: docker build -t cyroid/redteam-vpn:latest .
# Size: ~25MB

FROM alpine:3.19

COPY server.conf /etc/openvpn/
COPY auth-pam.conf /etc/pam.d/openvpn
COPY entrypoint.sh /

RUN apk add --no-cache \
        openvpn \
        easy-rsa \
        bash \
        iptables \
        linux-pam \
        openvpn-auth-pam \
        shadow \
    # Set up Easy-RSA PKI
    && mkdir -p /etc/openvpn/easy-rsa \
    && ln -s /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/ \
    && cd /etc/openvpn/easy-rsa \
    && ./easyrsa init-pki \
    && echo "ACME Widgets VPN CA" | ./easyrsa build-ca nopass \
    && ./easyrsa gen-dh \
    && ./easyrsa build-server-full server nopass \
    && ./easyrsa build-client-full client nopass \
    && openvpn --genkey secret /etc/openvpn/ta.key \
    && cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/ \
    # Create VPN users
    && adduser -D -s /bin/false vpnuser && echo "vpnuser:VPN2024!" | chpasswd \
    && adduser -D -s /bin/false jsmith && echo "jsmith:Summer2024" | chpasswd \
    && adduser -D -s /bin/false mwilliams && echo "mwilliams:Welcome123" | chpasswd \
    # Cleanup PKI build files to reduce size
    && rm -rf /etc/openvpn/easy-rsa/pki/reqs /etc/openvpn/easy-rsa/pki/private \
    && chmod +x /entrypoint.sh

EXPOSE 1194/udp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openvpn", "--config", "/etc/openvpn/server.conf"]

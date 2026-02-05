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

FROM alpine:3.19

# Install OpenVPN and dependencies
RUN apk add --no-cache \
    openvpn \
    easy-rsa \
    bash \
    iptables \
    openssl \
    linux-pam \
    openvpn-auth-pam \
    shadow

# Set up Easy-RSA PKI
RUN mkdir -p /etc/openvpn/easy-rsa && \
    ln -s /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/

WORKDIR /etc/openvpn/easy-rsa

# Initialize PKI and generate certs
RUN ./easyrsa init-pki && \
    echo "ACME Widgets VPN CA" | ./easyrsa build-ca nopass && \
    ./easyrsa gen-dh && \
    ./easyrsa build-server-full server nopass && \
    ./easyrsa build-client-full client nopass && \
    openvpn --genkey secret /etc/openvpn/ta.key

# Copy certificates to openvpn dir
RUN cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/

# Create VPN users
RUN adduser -D -s /bin/false vpnuser && echo "vpnuser:VPN2024!" | chpasswd && \
    adduser -D -s /bin/false jsmith && echo "jsmith:Summer2024" | chpasswd && \
    adduser -D -s /bin/false mwilliams && echo "mwilliams:Welcome123" | chpasswd

# Configure OpenVPN server
COPY server.conf /etc/openvpn/server.conf
COPY auth-pam.conf /etc/pam.d/openvpn
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1194/udp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openvpn", "--config", "/etc/openvpn/server.conf"]

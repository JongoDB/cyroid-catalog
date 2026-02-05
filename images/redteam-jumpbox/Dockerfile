# CYROID Red Team Lab - Jump Box / Bastion Host
# SSH gateway to internal network with some basic tools
#
# Credentials:
# - admin:JumpB0x2024! (sudo)
# - svc_backup:Backup2024 (limited)
#
# Build: docker build -t cyroid/redteam-jumpbox:latest .

FROM alpine:3.19

# Install SSH and basic tools
RUN apk add --no-cache \
    openssh-server \
    openssh-client \
    bash \
    curl \
    vim \
    sudo \
    shadow \
    && mkdir -p /var/run/sshd \
    && ssh-keygen -A

# Create users
RUN adduser -D -s /bin/bash admin && \
    echo "admin:JumpB0x2024!" | chpasswd && \
    adduser admin wheel && \
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers && \
    adduser -D -s /bin/bash svc_backup && \
    echo "svc_backup:Backup2024" | chpasswd

# Configure SSH
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config

# Add MOTD banner
RUN cat > /etc/motd << 'EOF'
================================================================================
                    ACME WIDGETS - JUMP BOX
================================================================================
  Authorized access only. All sessions are logged and monitored.

  For internal network access, contact IT Security.
================================================================================
EOF

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]

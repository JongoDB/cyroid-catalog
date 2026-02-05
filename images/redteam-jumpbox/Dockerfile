# CYROID Red Team Lab - Jump Box / Bastion Host
# SSH gateway to internal network
#
# Credentials:
# - admin:JumpB0x2024! (sudo)
# - svc_backup:Backup2024 (limited)
#
# Build: docker build -t cyroid/redteam-jumpbox:latest .
# Size: ~12MB

FROM alpine:3.19

RUN apk add --no-cache \
        openssh-server \
        bash \
        sudo \
        shadow \
    && mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    # Create users
    && adduser -D -s /bin/bash admin \
    && echo "admin:JumpB0x2024!" | chpasswd \
    && adduser admin wheel \
    && echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers \
    && adduser -D -s /bin/bash svc_backup \
    && echo "svc_backup:Backup2024" | chpasswd \
    # Configure SSH
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo -e "AllowTcpForwarding yes\nGatewayPorts yes" >> /etc/ssh/sshd_config \
    # MOTD banner
    && echo '================================================================================\n                    ACME WIDGETS - JUMP BOX\n================================================================================\n  Authorized access only. All sessions are logged and monitored.\n================================================================================' > /etc/motd

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]

# CYROID Red Team Lab - FTP Server
# vsftpd with anonymous access and weak credentials
#
# Credentials:
# - anonymous (read-only public files)
# - ftpuser:Ftp2024! (read/write to uploads)
# - svc_backup:Backup2024 (access to backups share)
#
# Build: docker build -t cyroid/redteam-ftp:latest .

FROM alpine:3.19

# Install vsftpd
RUN apk add --no-cache \
    vsftpd \
    bash \
    shadow

# Create FTP directories
RUN mkdir -p /var/ftp/public /var/ftp/uploads /var/ftp/backups && \
    chmod 755 /var/ftp/public && \
    chmod 777 /var/ftp/uploads && \
    chmod 750 /var/ftp/backups

# Create users
RUN adduser -D -h /var/ftp ftpuser && \
    echo "ftpuser:Ftp2024!" | chpasswd && \
    adduser -D -h /var/ftp svc_backup && \
    echo "svc_backup:Backup2024" | chpasswd && \
    chown svc_backup:svc_backup /var/ftp/backups

# Add some interesting files
RUN cat > /var/ftp/public/welcome.txt << 'EOF'
================================================================================
                    ACME WIDGETS FTP SERVER
================================================================================
Welcome to the Acme Widgets public FTP server.

Public files are available in /public
Authenticated users can upload to /uploads

For access requests, contact: it-support@acmewidgets.local
================================================================================
EOF

RUN cat > /var/ftp/public/network-diagram.txt << 'EOF'
ACME WIDGETS NETWORK DIAGRAM (OUTDATED - Q1 2023)
================================================

Internet
   |
   +-- Firewall (172.16.0.1)
          |
          +-- DMZ (172.16.1.0/24)
          |     +-- webserver (.10)
          |     +-- jumpbox (.20)
          |     +-- ftp (.30) <- You are here
          |     +-- jenkins (.40)
          |
          +-- Internal (172.16.2.0/24)
                +-- fileserver (.10)
                +-- workstations (.11+)
                +-- dc01 (.12)
                +-- wiki (.20)
                +-- ticketing (.30)

Note: This diagram may be outdated. Check wiki for current topology.
EOF

RUN cat > /var/ftp/backups/backup-readme.txt << 'EOF'
Backup Directory
================
This directory contains scheduled backups.

Backup schedule:
- Daily: config files
- Weekly: database dumps
- Monthly: full system images

Contact: svc_backup@acmewidgets.local
EOF

RUN cat > /var/ftp/backups/old-passwords.txt << 'EOF'
# ARCHIVED PASSWORDS - DO NOT USE
# These were rotated in Q4 2023
# Keeping for audit trail

Old service accounts:
- backup_old: BackupOld123
- deploy_svc: Deploy2023!
- monitoring: Monitor123

Note: New passwords are in the IT wiki
EOF

# Configure vsftpd
RUN cat > /etc/vsftpd/vsftpd.conf << 'EOF'
# CYROID Red Team Lab - vsftpd config
listen=YES
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_root=/var/ftp
local_root=/var/ftp
chroot_local_user=YES
allow_writeable_chroot=YES
anon_upload_enable=NO
anon_mkdir_write_enable=NO
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30100
seccomp_sandbox=NO
EOF

EXPOSE 20 21 30000-30100
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]

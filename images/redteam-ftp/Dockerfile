# CYROID Red Team Lab - FTP Server
# vsftpd with anonymous access and weak credentials
#
# Credentials:
# - anonymous (read-only public files)
# - ftpuser:Ftp2024! (read/write to uploads)
# - svc_backup:Backup2024 (access to backups share)
#
# Build: docker build -t cyroid/redteam-ftp:latest .
# Size: ~8MB

FROM alpine:3.19

# All setup in single RUN to minimize layers
RUN apk add --no-cache vsftpd shadow \
    # Create directories
    && mkdir -p /var/ftp/public /var/ftp/uploads /var/ftp/backups \
    && chmod 755 /var/ftp/public \
    && chmod 777 /var/ftp/uploads \
    && chmod 750 /var/ftp/backups \
    # Create users
    && adduser -D -h /var/ftp ftpuser \
    && echo "ftpuser:Ftp2024!" | chpasswd \
    && adduser -D -h /var/ftp svc_backup \
    && echo "svc_backup:Backup2024" | chpasswd \
    && chown svc_backup:svc_backup /var/ftp/backups \
    # Create public files
    && echo '================================================================================\n                    ACME WIDGETS FTP SERVER\n================================================================================\nWelcome to the Acme Widgets public FTP server.\n\nPublic files are available in /public\nAuthenticated users can upload to /uploads\n\nFor access requests, contact: it-support@acmewidgets.local\n================================================================================' > /var/ftp/public/welcome.txt \
    && echo 'ACME WIDGETS NETWORK DIAGRAM (OUTDATED - Q1 2023)\n================================================\n\nInternet\n   |\n   +-- Firewall (172.16.0.1)\n          |\n          +-- DMZ (172.16.1.0/24)\n          |     +-- webserver (.10)\n          |     +-- jumpbox (.20)\n          |     +-- ftp (.30) <- You are here\n          |     +-- jenkins (.40)\n          |\n          +-- Internal (172.16.2.0/24)\n                +-- fileserver (.10)\n                +-- workstations (.11+)\n                +-- dc01 (.12)\n                +-- wiki (.20)\n                +-- ticketing (.30)\n\nNote: This diagram may be outdated. Check wiki for current topology.' > /var/ftp/public/network-diagram.txt \
    && echo 'Backup Directory\n================\nThis directory contains scheduled backups.\n\nBackup schedule:\n- Daily: config files\n- Weekly: database dumps\n- Monthly: full system images\n\nContact: svc_backup@acmewidgets.local' > /var/ftp/backups/backup-readme.txt \
    && echo '# ARCHIVED PASSWORDS - DO NOT USE\n# These were rotated in Q4 2023\n# Keeping for audit trail\n\nOld service accounts:\n- backup_old: BackupOld123\n- deploy_svc: Deploy2023!\n- monitoring: Monitor123\n\nNote: New passwords are in the IT wiki' > /var/ftp/backups/old-passwords.txt \
    # Configure vsftpd
    && echo -e 'listen=YES\nanonymous_enable=YES\nlocal_enable=YES\nwrite_enable=YES\nanon_root=/var/ftp\nlocal_root=/var/ftp\nchroot_local_user=YES\nallow_writeable_chroot=YES\nanon_upload_enable=NO\nanon_mkdir_write_enable=NO\npasv_enable=YES\npasv_min_port=30000\npasv_max_port=30100\nseccomp_sandbox=NO' > /etc/vsftpd/vsftpd.conf

EXPOSE 21 30000-30100
CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]

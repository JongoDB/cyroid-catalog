#!/bin/bash
set -e

# CYROID Samba AD DC Entrypoint
# Handles initial domain provisioning and configuration

# Route through lab firewall gateway (.1) instead of Docker bridge
configure_routing() {
    local ip
    ip=$(hostname -I | awk '{print $1}')
    local gateway
    gateway=$(echo "$ip" | sed 's/\.[0-9]*$/.1/')
    if ! ip route show default | grep -q "via $gateway"; then
        ip route del default 2>/dev/null || true
        ip route add default via "$gateway" 2>/dev/null || true
    fi
}
configure_routing

echo "=== CYROID Samba AD DC ==="
echo "Domain: ${SAMBA_DOMAIN}"
echo "Realm: ${SAMBA_REALM}"

# Get hostname
HOSTNAME=$(hostname -s)
HOSTNAME_FQDN="${HOSTNAME}.$(echo ${SAMBA_REALM} | tr '[:upper:]' '[:lower:]')"

echo "Hostname: ${HOSTNAME}"
echo "FQDN: ${HOSTNAME_FQDN}"

# Check if already provisioned
if [ ! -f /var/lib/samba/private/secrets.keytab ]; then
    echo ""
    echo "=== Provisioning new domain ==="

    # Remove any existing config
    rm -f /etc/samba/smb.conf
    rm -rf /var/lib/samba/*
    rm -rf /var/cache/samba/*
    rm -f /etc/krb5.conf

    # Provision the domain
    samba-tool domain provision \
        --use-rfc2307 \
        --realm="${SAMBA_REALM}" \
        --domain="${SAMBA_DOMAIN}" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --adminpass="${SAMBA_ADMIN_PASS}" \
        --host-name="${HOSTNAME}" \
        --option="dns forwarder = ${SAMBA_DNS_FORWARDER}"

    # Copy generated krb5.conf
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

    echo ""
    echo "=== Domain provisioned successfully ==="
    echo "Administrator password: ${SAMBA_ADMIN_PASS}"
    echo ""

    # Create some test users if requested
    if [ "${CREATE_TEST_USERS}" = "true" ]; then
        echo "Creating test users..."

        # Create users matching the red team training lab walkthrough
        samba-tool user create jsmith "Summer2024" \
            --given-name="John" --surname="Smith" \
            --mail-address="jsmith@$(echo ${SAMBA_REALM} | tr '[:upper:]' '[:lower:]')" \
            || true

        samba-tool user create mwilliams "Welcome123" \
            --given-name="Mary" --surname="Williams" \
            --mail-address="mwilliams@$(echo ${SAMBA_REALM} | tr '[:upper:]' '[:lower:]')" \
            || true

        samba-tool user create svc_backup "Backup2024" \
            --given-name="Backup" --surname="Service" \
            --description="Backup service account with file server access" \
            || true

        echo "Test users created: jsmith, mwilliams, svc_backup"
    fi

else
    echo ""
    echo "=== Domain already provisioned, starting services ==="
fi

# Fix permissions
chown -R root:root /var/lib/samba
chmod 700 /var/lib/samba/private

# Display connection info
echo ""
echo "=== Connection Information ==="
echo "Domain: ${SAMBA_DOMAIN}"
echo "Realm: ${SAMBA_REALM}"
echo "DC Hostname: ${HOSTNAME}"
echo ""
echo "LDAP: ldap://${HOSTNAME_FQDN}:389"
echo "LDAPS: ldaps://${HOSTNAME_FQDN}:636"
echo "Kerberos: ${SAMBA_REALM}"
echo ""
echo "Administrator: Administrator@${SAMBA_REALM}"
echo ""

# Execute CMD (supervisord)
exec "$@"

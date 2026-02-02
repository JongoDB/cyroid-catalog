# Red Team Training Lab v2

A comprehensive penetration testing training environment with full walkthrough guide.

## Overview

This blueprint provides a realistic red team training scenario covering:
- Network reconnaissance and enumeration
- SQL injection attacks
- Credential harvesting and reuse
- Lateral movement techniques
- Active Directory/Samba domain compromise

## Network Architecture

```
INTERNET (172.16.0.0/24)
├── kali (172.16.0.10)         ← Attack box (multi-homed)
└── webserver (172.16.0.100)   ← WordPress target

DMZ (172.16.1.0/24)
├── kali (172.16.1.47)         ← Attack box secondary
└── webserver (172.16.1.10)    ← WordPress internal

INTERNAL (172.16.2.0/24)
├── kali (172.16.2.43)         ← Attack box internal access
├── fileserver (172.16.2.10)   ← SMB File Server
├── ws01 (172.16.2.11)         ← Employee Workstation
└── dc01 (172.16.2.12)         ← Samba Domain Controller
```

## What's New in v2

- **Multi-NIC VMs**: Kali attack box now has interfaces on all three networks
- **Webserver dual-homed**: Accessible from both internet and DMZ
- **Full walkthrough content**: 5-phase student guide with 20 steps
- **Container runtime options**: Samba DC properly configured with privileged mode

## Required Images

- `cyroid/kali-attack:latest`
- `cyroid/redteam-lab-wordpress:latest`
- `cyroid/redteam-lab-fileserver:latest`
- `cyroid/redteam-lab-workstation:latest`
- `cyroid/samba-dc:latest`

## Walkthrough Phases

1. **Reconnaissance** - Network discovery and service enumeration
2. **SQL Injection** - Exploiting the WordPress employee directory
3. **Lateral Movement** - Credential reuse to access file server
4. **Domain Compromise** - Obtaining Domain Admin credentials
5. **Post-Exploitation** - LDAP enumeration and persistence

## Usage

Install from the CYROID catalog browser or import the blueprint directly.

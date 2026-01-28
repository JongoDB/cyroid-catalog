# Red Team Training Lab

Comprehensive red team training environment simulating an enterprise network attack chain from initial reconnaissance through domain compromise.

## Overview

Students play the role of a penetration tester hired to assess **Acme Widgets'** security. Starting from a Kali attack box on the "internet" network, they must discover and exploit vulnerabilities to gain Domain Admin access.

## Attack Path

```
Reconnaissance → SQL Injection → Credential Theft → Lateral Movement → Domain Compromise
```

1. **Reconnaissance** - nmap discovery of the WordPress server
2. **SQL Injection** - Exploit vulnerable employee directory to extract VPN credentials
3. **Lateral Movement** - Use stolen credentials to access internal file server via SMB
4. **Domain Compromise** - Find Domain Admin password in sensitive files, verify access to DC

## Network Architecture

| Network | Subnet | Purpose |
|---------|--------|---------|
| internet | 172.16.0.0/24 | External attacker network |
| dmz | 172.16.1.0/24 | DMZ with web server |
| internal | 172.16.2.0/24 | Corporate internal network |

## VMs

| Hostname | Image | Network | Role |
|----------|-------|---------|------|
| kali | cyroid/kali-attack | internet | Attack platform |
| redir1 | alpine | internet | C2 redirector |
| redir2 | alpine | internet | C2 redirector |
| webserver | cyroid/redteam-lab-wordpress | dmz | Vulnerable WordPress |
| dc01 | cyroid/samba-dc | internal | Domain Controller |
| fileserver | cyroid/redteam-lab-fileserver | internal | SMB file server |
| ws01 | cyroid/redteam-lab-workstation | internal | Employee workstation |

## Required Images

- `cyroid/kali-attack` (from catalog: `images/kali-attack`)
- `cyroid/samba-dc` (from catalog: `images/samba-dc`)
- `cyroid/redteam-lab-wordpress` (from catalog: `images/redteam-lab-wordpress`)
- `cyroid/redteam-lab-fileserver` (from catalog: `images/redteam-lab-fileserver`)
- `cyroid/redteam-lab-workstation` (from catalog: `images/redteam-lab-workstation`)
- `alpine:latest` (public Docker Hub)

## Included Content

- **Student Guide** - 5-phase walkthrough covering recon through post-exploitation
- **MSEL** - 5 timed events for instructor-paced delivery

## Difficulty

Intermediate - suitable for students with basic Linux and networking knowledge.

## Tags

`red-team`, `penetration-testing`, `sql-injection`, `lateral-movement`, `active-directory`, `training`

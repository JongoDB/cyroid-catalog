# Red Team Training Lab v3

Advanced penetration testing training environment with **realistic network segmentation**.

## What's New in v3

Unlike v2 where Kali had interfaces on all networks, **v3 requires actual pivoting**:

| Feature | v2 | v3 |
|---------|----|----|
| Kali network access | All 3 networks | Internet only |
| Routing | None (multi-homed) | Firewall with NAT |
| Pivoting required | No | Yes (SSH tunnels) |
| Attack surfaces | 5 VMs | 12 VMs |
| Attack paths | 1 primary | 3+ alternatives |

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INTERNET (172.16.0.0/24)                              │
│                                                                              │
│  ┌──────────┐         ┌──────────┐         ┌──────────┐                     │
│  │  KALI    │         │ FIREWALL │         │   VPN    │                     │
│  │  .10     │         │  .1 (GW) │         │   .50    │                     │
│  │ Attacker │         │  NAT:    │         │ OpenVPN  │                     │
│  │          │         │ .100:80  │         │          │                     │
│  └──────────┘         │ .100:8080│         └────┬─────┘                     │
│       │               └────┬─────┘              │                           │
│       │                    │                    │                           │
│       └────────────────────┼────────────────────┘                           │
│              Can only see  │  firewall NAT'd services                       │
└────────────────────────────┼────────────────────────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────────────────────────┐
│                        DMZ (172.16.1.0/24)                                   │
│                            │                                                 │
│  ┌──────────┐    ┌────────┴───────┐    ┌──────────┐    ┌──────────┐        │
│  │WEBSERVER │    │    FIREWALL    │    │ JUMPBOX  │    │ JENKINS  │        │
│  │   .10    │    │    .1 (GW)     │    │   .20    │    │   .40    │        │
│  │WordPress │    │                │    │ Bastion  │    │  CI/CD   │        │
│  │  SQLi    │    │                │    │          │    │ Groovy   │        │
│  └──────────┘    └────────┬───────┘    └──────────┘    └──────────┘        │
│                           │                                                  │
│  ┌──────────┐             │                                                  │
│  │   FTP    │             │                                                  │
│  │   .30    │             │                                                  │
│  │ vsftpd   │             │                                                  │
│  └──────────┘             │                                                  │
└───────────────────────────┼─────────────────────────────────────────────────┘
                            │
┌───────────────────────────┼─────────────────────────────────────────────────┐
│                     INTERNAL (172.16.2.0/24)                                 │
│                           │                                                  │
│  ┌──────────┐    ┌────────┴───────┐    ┌──────────┐    ┌──────────┐        │
│  │FILESERVER│    │    FIREWALL    │    │   WIKI   │    │TICKETING │        │
│  │   .10    │    │    .1 (GW)     │    │   .20    │    │   .30    │        │
│  │   SMB    │    │                │    │ DokuWiki │    │ osTicket │        │
│  └──────────┘    └────────────────┘    └──────────┘    └──────────┘        │
│                                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │   WS01   │    │   DC01   │    │   DB01   │    │   VPN    │              │
│  │   .11    │    │   .12    │    │   .40    │    │   .50    │              │
│  │Workstation│   │Samba DC  │    │  MySQL   │    │ internal │              │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Attack Paths

### Path 1: SQLi → SSH Pivot → Domain Compromise (Primary)

1. **Recon**: Scan 172.16.0.0/24, find firewall NAT exposing :80 and :8080
2. **SQLi**: Exploit WordPress employee directory, extract `svc_backup` creds
3. **Pivot**: SSH to webserver (172.16.1.10) with stolen creds
4. **Tunnel**: Set up SOCKS proxy: `ssh -D 9050 svc_backup@172.16.1.10`
5. **DMZ Enum**: Through proxy, discover jumpbox, FTP, Jenkins
6. **Internal**: Use jumpbox or extend tunnel to reach 172.16.2.0/24
7. **Lateral**: Access fileserver with svc_backup creds → find passwords.txt
8. **Domain**: Use Domain Admin creds on DC01

### Path 2: Jenkins RCE → Internal Access

1. Find Jenkins on 172.16.0.100:8080
2. Access Groovy script console (weak/default auth)
3. Execute reverse shell payload
4. Pivot from Jenkins to internal network

### Path 3: VPN Credential Stuffing

1. Find VPN on 172.16.0.50:1194
2. Use credentials extracted from SQLi
3. Connect to VPN → direct internal network access
4. Skip all pivoting, go straight to internal enum

## Required Images

| Image | Network | Purpose |
|-------|---------|---------|
| `cyroid/kali-attack` | Internet | Attacker workstation |
| `cyroid/redteam-firewall` | All | NAT/routing/firewall |
| `cyroid/redteam-vpn` | Internet+Internal | VPN gateway |
| `cyroid/redteam-lab-wordpress` | DMZ | SQLi target |
| `cyroid/redteam-jumpbox` | DMZ | Bastion host |
| `cyroid/redteam-ftp` | DMZ | FTP with weak auth |
| `cyroid/redteam-jenkins` | DMZ | CI/CD with Groovy |
| `cyroid/redteam-lab-fileserver` | Internal | SMB with secrets |
| `cyroid/redteam-lab-workstation` | Internal | Employee PC |
| `cyroid/samba-dc` | Internal | Domain Controller |
| `cyroid/redteam-wiki` | Internal | Internal docs |
| `cyroid/redteam-ticketing` | Internal | IT ticketing |
| `cyroid/redteam-mysql` | Internal | Database |

## Skills Practiced

- Network reconnaissance through firewalls
- SQL injection exploitation
- SSH tunneling (local, remote, dynamic port forwarding)
- Proxychains configuration and usage
- Multi-hop pivoting
- Credential reuse attacks
- Jenkins exploitation
- VPN attacks
- Active Directory enumeration
- Lateral movement techniques

## Walkthrough Phases

1. **Reconnaissance** - Discover NAT'd services through firewall
2. **Initial Access** - SQL injection on WordPress
3. **Pivot Setup** - SSH tunnels and SOCKS proxy
4. **DMZ Exploration** - Enumerate through pivot
5. **Internal Access** - Reach corporate network
6. **Lateral Movement** - Credential reuse on fileserver
7. **Domain Compromise** - DC enumeration and persistence
8. **Alternative Paths** - Jenkins RCE, VPN access

## Comparison: When to Use v2 vs v3

| Use Case | Recommended Version |
|----------|---------------------|
| First-time pentest training | v2 (simpler) |
| Learning pivoting/tunneling | **v3** |
| Quick SQLi practice | v2 |
| Realistic network scenarios | **v3** |
| CTF-style challenges | v2 |
| Professional training | **v3** |

## Installation

Install from the CYROID catalog browser or import the blueprint directly.

```bash
# From CYROID UI
Catalog → Red Team Training Lab v3 → Install

# Or import blueprint file
Blueprints → Import → Select blueprint.yaml
```

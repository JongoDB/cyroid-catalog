# CYROID Red Team Firewall

Multi-homed firewall/router for the Red Team Training Lab v3.

## Purpose

Provides realistic network segmentation between:
- **Internet** (172.16.0.0/24) - Attacker's network
- **DMZ** (172.16.1.0/24) - Externally accessible services
- **Internal** (172.16.2.0/24) - Corporate infrastructure

## NAT Mappings

| External | Internal | Service |
|----------|----------|---------|
| 172.16.0.100:80 | 172.16.1.10:80 | Webserver HTTP |
| 172.16.0.100:443 | 172.16.1.10:443 | Webserver HTTPS |
| 172.16.0.100:8080 | 172.16.1.40:8080 | Jenkins |

## Allowed Traffic Flows

### Internet → DMZ
- NAT'd services only (webserver, jenkins)

### DMZ → Internal
- Jumpbox (.20) → Any internal host (SSH)
- Webserver (.10) → DB01 (.40) port 3306
- Jenkins (.40) → Fileserver (.10) port 445

### Internal → DMZ
- Any internal → Jumpbox (.20) SSH

## Container Requirements

```yaml
cap_add:
  - NET_ADMIN
  - NET_RAW
sysctls:
  net.ipv4.ip_forward: "1"
```

## Build

```bash
docker build -t cyroid/redteam-firewall:latest .
```

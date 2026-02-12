# CYROID ICS OT Engineering Workstation
# Desktop environment with ICS-specific tools for PLC programming and monitoring
#
# Based on kali-attack with additional ICS tools:
# - pymodbus (Modbus TCP client/server)
# - asyncua / uaclient (OPC UA client)
# - cpppo (EtherNet/IP client)
# - Wireshark (with ICS protocol dissectors)
# - Nmap ICS scripts
#
# Build: docker build -t cyroid/ics-eng-workstation:latest .
# Run:   docker run -d -p 6901:6901 -e VNC_PW=password cyroid/ics-eng-workstation:latest

ARG BASE_TAG="1.17.0"
FROM kasmweb/core-kali-rolling:${BASE_TAG}

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/kasm-default-profile

RUN wget -q -O /tmp/kali-key.asc https://archive.kali.org/archive-keyring.gpg \
    && cp /tmp/kali-key.asc /usr/share/keyrings/kali-archive-keyring.gpg \
    && apt-get update && apt-get install -y --no-install-recommends \
    wireshark-common tshark tcpdump nmap \
    openssh-server \
    python3-pip python3-venv \
    curl wget vim tmux jq \
    netcat-openbsd socat iproute2 iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ICS Python libraries
RUN pip install --no-cache-dir --break-system-packages \
    pymodbus==3.7.4 \
    asyncua==1.1.5 \
    cpppo==4.4.2

# Create ICS tools cheatsheet on desktop
COPY ICS_TOOLS_CHEATSHEET.md /home/kasm-default-profile/ICS_TOOLS_CHEATSHEET.md

# Gateway routing fix: Docker assigns bridge IP as default gateway,
# but CYROID labs use firewall VMs at .1 on each subnet.
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
fi\n\
# Start SSH server if installed (needed for pivot target role)\n\
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

RUN chown -R 1000:1000 /home/kasm-default-profile

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

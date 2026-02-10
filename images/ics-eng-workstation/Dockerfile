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
    python3-pip python3-venv \
    curl wget vim tmux jq \
    netcat-openbsd socat iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ICS Python libraries
RUN pip install --no-cache-dir --break-system-packages \
    pymodbus==3.7.4 \
    asyncua==1.1.5 \
    cpppo==4.4.2

# Create ICS tools cheatsheet on desktop
COPY ICS_TOOLS_CHEATSHEET.md /home/kasm-default-profile/ICS_TOOLS_CHEATSHEET.md

RUN chown -R 1000:1000 /home/kasm-default-profile

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

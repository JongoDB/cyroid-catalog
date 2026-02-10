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

# ICS tools via apt
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Network analysis
    wireshark-common tshark tcpdump nmap \
    # Development
    python3-pip python3-venv \
    # Utilities
    curl wget vim tmux jq \
    # Network tools
    netcat-openbsd socat iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ICS Python libraries
RUN pip install --no-cache-dir --break-system-packages \
    pymodbus==3.7.4 \
    asyncua==1.1.5 \
    cpppo==4.4.2

# Create ICS tools cheatsheet on desktop
RUN cat > /home/kasm-default-profile/ICS_TOOLS_CHEATSHEET.md << 'CHEAT'
# ICS Engineering Tools Cheatsheet

## Modbus TCP
# Read holding registers from PLC
pymodbus.console tcp --host 172.16.5.20 --port 502
# Quick read: python3 -c "from pymodbus.client import ModbusTcpClient; c=ModbusTcpClient('172.16.5.20'); c.connect(); print(c.read_holding_registers(0,10).registers)"

## OPC UA
# Browse OPC UA server
uadiscover opc.tcp://172.16.5.50:4840
uaclient -u opc.tcp://172.16.5.50:4840/cyroid/plc

## EtherNet/IP
# Read tags from EtherNet/IP device
python3 -m cpppo.server.enip.client --address 172.16.5.30:44818 --print "Turbine_Speed_RPM"

## Wireshark ICS Filters
# Modbus: modbus
# DNP3: dnp3
# EtherNet/IP: enip
# OPC UA: opcua
# CIP: cip

## Nmap ICS Scripts
nmap -sV --script modbus-discover -p 502 172.16.5.0/24
nmap -sV --script enip-info -p 44818 172.16.5.0/24
nmap -sV --script opcua-discover -p 4840 172.16.5.0/24
CHEAT

RUN chown -R 1000:1000 /home/kasm-default-profile

WORKDIR /home/kasm-user
USER 1000
EXPOSE 6901

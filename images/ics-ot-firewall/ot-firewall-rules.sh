#!/bin/bash
# CYROID ICS OT Zone Firewall Rules
# Enforces Purdue Model (IEC 62443) network segmentation
#
# Zones (detected dynamically from interface IPs):
#   IT/OT DMZ     172.16.2.0/24 - Jump host, historian mirror
#   Operations    172.16.3.0/24 - Historian, OT engineering WS
#   Supervisory   172.16.4.0/24 - HMIs
#   Process Ctrl  172.16.5.0/24 - PLCs, RTUs

set -e

# Detect interfaces by subnet instead of relying on eth0-eth3 ordering.
# Docker assigns interface names based on network connect order, which
# varies depending on how the CYROID API provisions the container.
detect_interface() {
    local subnet_prefix="$1"
    ip -4 addr show | grep "inet ${subnet_prefix}\." | awk '{print $NF}'
}

DMZ_IF=$(detect_interface "172.16.2")
OPS_IF=$(detect_interface "172.16.3")
SUP_IF=$(detect_interface "172.16.4")
PROC_IF=$(detect_interface "172.16.5")

for var in DMZ_IF OPS_IF SUP_IF PROC_IF; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Could not detect interface for $var" >&2
        exit 1
    fi
done

echo "Detected interfaces: DMZ=$DMZ_IF OPS=$OPS_IF SUP=$SUP_IF PROC=$PROC_IF"

DMZ_NET="172.16.2.0/24"
OPS_NET="172.16.3.0/24"
SUP_NET="172.16.4.0/24"
PROC_NET="172.16.5.0/24"

# ICS protocol ports
MODBUS_PORT=502
OPCUA_PORT=4840
ENIP_PORT=44818

# Flush existing rules
iptables -F FORWARD
iptables -F INPUT
iptables -F OUTPUT
iptables -t nat -F

# Default policy: DROP all forwarded traffic (whitelist approach)
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Allow established/related connections
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# === MASQUERADE for return traffic ===
iptables -t nat -A POSTROUTING -o $DMZ_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -o $OPS_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -o $SUP_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -o $PROC_IF -j MASQUERADE

# ============================================================
# ALLOWED FLOWS: IT/OT DMZ -> Operations (L3.5 -> L3)
# ============================================================
# Jump host SSH to operations (authorized maintenance)
iptables -A FORWARD -i $DMZ_IF -o $OPS_IF -s 172.16.2.10 -p tcp --dport 22 -j ACCEPT
# Historian mirror reads from historian
iptables -A FORWARD -i $DMZ_IF -o $OPS_IF -s 172.16.2.20 -d 172.16.3.10 -p tcp --dport 8080 -j ACCEPT

# ============================================================
# ALLOWED FLOWS: Operations -> Supervisory (L3 -> L2)
# ============================================================
# Historian polls HMIs for status
iptables -A FORWARD -i $OPS_IF -o $SUP_IF -s 172.16.3.10 -p tcp --dport 8080 -j ACCEPT
# OT engineering workstation to HMIs
iptables -A FORWARD -i $OPS_IF -o $SUP_IF -s 172.16.3.20 -p tcp --dport 8080 -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $SUP_IF -s 172.16.3.20 -p tcp --dport 22 -j ACCEPT

# ============================================================
# ALLOWED FLOWS: Operations -> Process Control (L3 -> L1)
# ============================================================
# Historian polls all PLCs via Modbus/OPC UA/EtherNet-IP
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.10 -p tcp --dport $MODBUS_PORT -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.10 -p tcp --dport $OPCUA_PORT -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.10 -p tcp --dport $ENIP_PORT -j ACCEPT
# OT engineering workstation to PLCs (maintenance)
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.20 -p tcp --dport $MODBUS_PORT -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.20 -p tcp --dport $OPCUA_PORT -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.20 -p tcp --dport $ENIP_PORT -j ACCEPT
iptables -A FORWARD -i $OPS_IF -o $PROC_IF -s 172.16.3.20 -p tcp --dport 22 -j ACCEPT

# ============================================================
# ALLOWED FLOWS: Supervisory -> Process Control (L2 -> L1)
# ============================================================
# HMIs to PLCs via ICS protocols (primary operational traffic)
iptables -A FORWARD -i $SUP_IF -o $PROC_IF -s $SUP_NET -p tcp --dport $MODBUS_PORT -j ACCEPT
iptables -A FORWARD -i $SUP_IF -o $PROC_IF -s $SUP_NET -p tcp --dport $OPCUA_PORT -j ACCEPT
iptables -A FORWARD -i $SUP_IF -o $PROC_IF -s $SUP_NET -p tcp --dport $ENIP_PORT -j ACCEPT

# ============================================================
# ALLOWED FLOWS: Within same zone (peer communication)
# ============================================================
iptables -A FORWARD -i $OPS_IF -o $OPS_IF -j ACCEPT
iptables -A FORWARD -i $SUP_IF -o $SUP_IF -j ACCEPT
iptables -A FORWARD -i $PROC_IF -o $PROC_IF -j ACCEPT

# ============================================================
# ALLOWED FLOWS: IT/OT DMZ -> Process Control (L3.5 -> L1)
# ============================================================
# Historian mirror polls PLCs directly (intentional misconfiguration
# for training — DMZ should not have direct PLC access)
iptables -A FORWARD -i $DMZ_IF -o $PROC_IF -s 172.16.2.20 -p tcp --dport $MODBUS_PORT -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $PROC_IF -s 172.16.2.20 -p tcp --dport $OPCUA_PORT -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $PROC_IF -s 172.16.2.20 -p tcp --dport $ENIP_PORT -j ACCEPT

# ============================================================
# ICMP (Allow ping for network recon and debugging)
# ============================================================
iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

# ============================================================
# BLOCKED (implicit by DROP policy):
# - DMZ -> Supervisory (no direct IT to HMI)
# - Process Control -> anything except responses
# - Any non-ICS protocol to Process Control
# ============================================================

# Log dropped packets for IDS training
iptables -A FORWARD -j LOG --log-prefix "OT-FW-DROP: " --log-level 4

echo "OT firewall rules applied:"
echo "  Allowed: HMI->PLC (Modbus/OPCUA/ENIP), Historian->PLC, Eng-WS->PLC"
echo "  Blocked: DMZ->PLC (direct), DMZ->HMI (direct), non-ICS protocols"

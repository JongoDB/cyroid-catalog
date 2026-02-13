# ICS Power Grid Defense Lab

ICS/SCADA defensive training environment for network security operations teams protecting electric power grid infrastructure.

## Overview

This blueprint creates a full Purdue Model (IEC 62443) environment where blue team defenders must detect and respond to a sophisticated IT-to-OT kill chain attack targeting industrial control systems that manage power generation, transmission, and distribution.

### Defensive Capabilities
- **IDS with ICS Rulesets**: Suricata with ET ICS, Quickdraw SCADA rules monitoring OT zones
- **SIEM**: Wazuh collecting logs from all 15 IT and OT endpoints
- **Traffic Mirroring**: Mirrored traffic on enterprise, IT/OT DMZ, supervisory, operations, and process control networks
- **PCAP Capture**: Full packet capture on all mirrored zones
- **Detection Scoring**: Automated scoring with MITRE ATT&CK for ICS mapping
- **IOC Submission**: Student IOC submission with instructor grading
- **Threat Hunting**: Structured OT-aware threat hunt workflows
- **Forensic Findings**: ICS-specific forensic evidence documentation

### Industrial Protocols
- **Modbus TCP** (port 502) - PLCs: Substation B breaker, Load management
- **DNP3** (port 20000) - PLCs: Substation A protection relay, Distribution RTU
- **EtherNet/IP** (port 44818) - PLC: Turbine governor
- **OPC UA** (port 4840) - PLC: Safety instrumented system

## Network Architecture (Purdue Model)

```
L5 INTERNET            L4 ENTERPRISE           L3.5 IT/OT DMZ         L3 OPERATIONS
172.16.0.0/24          172.16.1.0/24           172.16.2.0/24          172.16.3.0/24
┌──────────────┐       ┌──────────────┐        ┌──────────────┐       ┌──────────────┐
│   attacker   │       │    dc01      │        │  jump-host   │       │  historian   │
│   .0.10      │       │    .1.10     │        │  .2.10       │       │  .3.10       │
└──────┬───────┘       │  mail-srv    │        │              │       │              │
       │               │    .1.20     │        │ hist-mirror  │       │  eng-ws-ot   │
       │               │   eng-ws     │        │  .2.20       │       │  .3.20       │
       │               │    .1.30     │        └──────┬───────┘       └──────┬───────┘
       │               │  corp-web    │               │                      │
       │               │    .1.40     │               │                      │
       │               └──────┬───────┘        ┌──────┴───────┐              │
       │                      │                │ ot-firewall  │──────────────┘
       │               ┌──────┴───────┐        │  .2.254      │
       └──────────────▶│ ent-firewall │────────┤  .3.1        │
                       │  .0.1        │        │  .4.1        │
                       │  .1.1        │        │  .5.1        │
                       │  .2.1        │        └──────┬───────┘
                       └──────────────┘               │
                                                      │
                    ┌─────────────────────────────────┴──────────────────────────┐
                    │                                                            │
          L2 SUPERVISORY / HMI                              L1/L0 PROCESS CONTROL
          172.16.4.0/24                                     172.16.5.0/24
          ┌──────────────┐                                  ┌─────────────────────────┐
          │  hmi-sub     │─────────────────────────────────▶│ plc-sub-a  .5.10  DNP3  │
          │  .4.10       │─────────────────────────────────▶│ plc-sub-b  .5.20  Modbus│
          │              │                                  │                         │
          │  hmi-gen     │─────────────────────────────────▶│ plc-gen    .5.30  EIP   │
          │  .4.20       │─────────────────────────────────▶│ plc-load   .5.40  Modbus│
          │              │                                  │                         │
          │  hmi-grid    │─────── reads from all ──────────▶│ plc-safety .5.50  OPCUA │
          │  .4.30       │                                  │ rtu-dist   .5.60  DNP3  │
          └──────────────┘                                  └─────────────────────────┘

          SOC MONITORING
          172.16.6.0/24
          ┌──────────────┐    Monitor-mode on:
          │  ids-sensor  │◄── IT/OT DMZ (.2.250)
          │  .6.10       │◄── Supervisory (.4.250)
          │              │◄── Process Control (.5.250)
          │  siem        │
          │  .6.20       │
          │              │
          │  soc-analyst │
          │  .6.100      │
          └──────────────┘
```

## VMs (23 total)

| Hostname | Purdue Level | Network | IP Address | Role | Protocol | Image |
|----------|-------------|---------|------------|------|----------|-------|
| attacker | L5 | internet | .0.10 | Red team attack source | - | kali-attack |
| ent-firewall | L4/L5 | internet/enterprise/dmz | .0.1/.1.1/.2.1 | Enterprise perimeter | - | redteam-firewall |
| dc01 | L4 | enterprise | .1.10 | Domain controller | - | samba-dc |
| mail-srv | L4 | enterprise | .1.20 | Email server | - | kali-attack |
| eng-ws | L4 | enterprise | .1.30 | Engineer workstation | - | redteam-lab-workstation |
| corp-web | L4 | enterprise | .1.40 | Corporate web portal | - | redteam-lab-wordpress |
| jump-host | L3.5 | it-ot-dmz | .2.10 | IT-to-OT access point | - | kali-attack |
| hist-mirror | L3.5 | it-ot-dmz | .2.20 | Read-only historian mirror | - | ics-historian |
| ot-firewall | L3/L3.5 | dmz/ops/sup/proc | .2.254/.3.1/.4.1/.5.1 | OT perimeter | - | ics-ot-firewall |
| historian | L3 | operations | .3.10 | Process data historian | - | ics-historian |
| eng-ws-ot | L3 | operations | .3.20 | OT engineering workstation | - | ics-eng-workstation |
| hmi-sub | L2 | supervisory + proc | .4.10/.5.100 | Substation operations | DNP3/Modbus | ics-hmi |
| hmi-gen | L2 | supervisory + proc | .4.20/.5.101 | Generation plant control | EIP/Modbus | ics-hmi |
| hmi-grid | L2 | supervisory | .4.30 | Grid overview / EMS | All (read) | ics-hmi |
| plc-sub-a | L1 | process-control | .5.10 | Protection relay | DNP3 | ics-plc-sim |
| plc-sub-b | L1 | process-control | .5.20 | Breaker controller | Modbus TCP | ics-plc-sim |
| plc-gen | L1 | process-control | .5.30 | Turbine governor | EtherNet/IP | ics-plc-sim |
| plc-load | L1 | process-control | .5.40 | Load management | Modbus TCP | ics-plc-sim |
| plc-safety | L1 | process-control | .5.50 | Safety system (SIS) | OPC UA | ics-plc-sim |
| rtu-dist | L1 | process-control | .5.60 | Distribution RTU | DNP3 | ics-plc-sim |
| ids-sensor | SOC | soc + monitor | .6.10 | Suricata IDS | - | kali-attack |
| siem | SOC | soc | .6.20 | Wazuh SIEM | - | kali-attack |
| soc-analyst | SOC | soc | .6.100 | Student workstation | - | kali-attack |

## Resource Requirements

| Resource | Total |
|----------|-------|
| vCPUs | ~30 |
| RAM | ~29 GB |
| Disk | ~440 GB |

## Exercise Flow (Full IT-to-OT Kill Chain)

| Phase | Time | Title | MITRE ATT&CK | Zone |
|-------|------|-------|---------------|------|
| 1 | T+0m | Exercise Start - OT Baseline | - | All |
| 2 | T+10m | External Reconnaissance | T1046 | L5 → L4 |
| 3 | T+20m | Spearphishing Engineer | T1566.001, T1059.001 | L4 |
| 4 | T+35m | AD Credential Harvesting | T1003.001, T1087.002 | L4 |
| 5 | T+50m | IT-to-OT Pivot via Jump Host | T1021.004, T0886 | L4 → L3.5 |
| 6 | T+65m | OT Protocol Scanning | T0846, T0842 | L3.5 → L1 |
| 7 | T+80m | HMI Display Manipulation | T0831 | L2 |
| 8 | T+95m | PLC Setpoint Modification | T0836, T0855 | L1 |
| 9 | T+110m | Safety System Bypass | T0880, T0857 | L1 (SIS) |
| 10 | T+120m | Grid Disruption / Blackout | T0826, T0813 | L0-L2 |
| 11 | T+130m | Incident Response | - | All |

## API Usage Examples

### PCAP Capture on OT Networks
```bash
# Start capture on Process Control network
curl -X POST /api/v1/ranges/{range_id}/pcap \
  -d '{"name": "Process Control capture", "network_id": "<process-control-network-id>"}'

# Start capture on Supervisory network
curl -X POST /api/v1/ranges/{range_id}/pcap \
  -d '{"name": "Supervisory HMI capture", "network_id": "<supervisory-network-id>"}'

# Stop capture
curl -X POST /api/v1/ranges/{range_id}/pcap/{capture_id}/stop

# List all captures
curl /api/v1/ranges/{range_id}/pcap
```

### Detection Scoring with ICS Techniques
```bash
# Create ICS-specific scoring rule
curl -X POST /api/v1/ranges/{range_id}/detection/rules \
  -d '{"name": "Detect Unauthorized Modbus Write", "rule_type": "network_alert", "max_points": 25, "mitre_technique": "T0836"}'

# Submit detection (student)
curl -X POST /api/v1/ranges/{range_id}/detection/scores \
  -d '{"rule_id": "<rule-id>", "status": "detected", "evidence": "Modbus FC16 Write Multiple Registers to plc-sub-b from 172.16.2.10"}'

# Get scoreboard
curl /api/v1/ranges/{range_id}/detection/scoreboard
```

### IOC Submission
```bash
# Submit ICS-specific IOC
curl -X POST /api/v1/ranges/{range_id}/detection/iocs \
  -d '{"ioc_type": "ip_address", "value": "172.16.2.10", "source": "IDS alert - unauthorized Modbus traffic from DMZ", "confidence": "high"}'

# Grade IOC (instructor)
curl -X PUT /api/v1/ranges/{range_id}/detection/iocs/{ioc_id}/grade \
  -d '{"is_correct": true, "points": 10.0, "feedback": "Correct - jump host was compromised and used as pivot"}'
```

### Threat Hunt
```bash
# Start ICS threat hunt
curl -X POST /api/v1/ranges/{range_id}/detection/hunts \
  -d '{"name": "IT-to-OT Pivot Hunt", "hypothesis": "Attacker crossed from IT to OT via jump host using stolen engineer credentials", "data_sources": ["pcap", "syslog", "ids_alerts"]}'

# Submit forensic finding
curl -X POST /api/v1/ranges/{range_id}/detection/forensics \
  -d '{"finding_type": "process_manipulation", "title": "Unauthorized Modbus write to breaker PLC", "mitre_technique": "T0836", "description": "Modbus FC16 write to holding registers 100-105 on plc-sub-b from 172.16.2.10 at 14:35:22 UTC. Changed breaker control registers from 0x0001 (closed) to 0x0000 (open)."}'
```

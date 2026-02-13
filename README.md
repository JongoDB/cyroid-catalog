# CYROID Catalog

Training content catalog for [CYROID](https://github.com/JongoDB/CYROID) (Cyber Range Orchestrator In Docker).

CYROID Catalog provides ready-to-deploy range blueprints, VM images, and scenario timelines for cybersecurity training. Each blueprint defines a complete lab environment — networks, VMs, firewall rules, and guided walkthroughs — that CYROID provisions as isolated Docker-in-Docker ranges.

---

## Blueprints

Blueprints are self-contained lab packages. Each one defines the network topology, VM images, firewall rules, walkthrough content, and scoring criteria for a training exercise.

### ICS Power Grid Defense Lab

Full IEC 62443 Purdue Model electric power grid with IT-to-OT attack chain and blue team defense.

| Zone | VMs | Purpose |
|------|-----|---------|
| L5 Internet | Kali attacker | External threat actor |
| L4 Enterprise | Domain controller, mail server, engineering WS, WordPress | Corporate IT |
| L3.5 IT/OT DMZ | Jump host, historian mirror | Segmentation boundary |
| L3 Operations | Historian, OT engineering workstation | Plant operations |
| L2 Supervisory | 3 HMI dashboards (Substation, Generation, Grid) | SCADA displays |
| L1/L0 Process Control | 6 PLCs/RTUs (Modbus TCP, OPC UA, EtherNet/IP) | Field devices |
| SOC | IDS sensor, SIEM, analyst workstation | Detection & response |

**Protocols:** Modbus TCP (502), OPC UA (4840), EtherNet/IP (44818)
**Red team path:** Recon &rarr; SQLi &rarr; credential harvest &rarr; SSH pivot chain &rarr; OT enumeration &rarr; HMI manipulation &rarr; PLC register modification
**Blue team:** IDS tuning, SIEM correlation, PCAP analysis, MITRE ATT&CK for ICS detection scoring

### Red Team Training Lab v3

Advanced corporate penetration testing with realistic network segmentation requiring pivoting through compromised hosts.

| Segment | VMs | Purpose |
|---------|-----|---------|
| Internet | Kali attacker | External attacker with VPN client |
| DMZ | WordPress, Jenkins, FTP, jump box | Externally exposed services |
| Internal | File server, domain controller, wiki, ticketing, MySQL, workstation | Corporate LAN |

**Attack paths:** SQL injection, Jenkins Script Console RCE, VPN credential stuffing, SMB relay, Kerberoasting
**Pivoting:** SSH tunneling and proxychains required for lateral movement — no shortcuts

### Red Team Training Lab v1 / v2

Introductory red team exercises with WordPress exploitation, Samba DC, and credential-based lateral movement. Good starting point before v3.

---

## Images

Docker images are the building blocks of blueprints. Each image is a purpose-built container with the tools, services, and intentional vulnerabilities needed for its training role.

### ICS / SCADA

| Image | Description | Protocols |
|-------|-------------|-----------|
| `ics-plc-sim` | Universal PLC simulator with configurable register maps | Modbus TCP, OPC UA, EtherNet/IP |
| `ics-hmi` | Web-based SCADA HMI dashboard polling PLCs in real time | HTTP (8080) |
| `ics-historian` | Process data historian with REST API and time-series storage | HTTP (8080) |
| `ics-eng-workstation` | KasmVNC desktop with pymodbus, asyncua, cpppo, Wireshark | VNC (6901) |
| `ics-ot-firewall` | Purdue Model zone firewall (whitelist ICS protocols only) | iptables |

### Red Team / Pentest

| Image | Description | Role |
|-------|-------------|------|
| `kali-attack` | Lightweight Kali with Impacket, NetExec, Hydra, Nmap | Attacker workstation |
| `redteam-firewall` | Multi-homed iptables router with NAT and DNAT | Network segmentation |
| `redteam-vpn` | OpenVPN gateway accepting credentials found via SQLi | Pivot point |
| `redteam-jenkins` | Jenkins with Script Console enabled and weak credentials | RCE target |
| `redteam-lab-wordpress` | WordPress with vulnerable plugin (SQLi, XSS) | Initial access target |
| `redteam-lab-workstation` | Victim workstation with automated browsing | BeEF / XSS target |
| `redteam-lab-fileserver` | SMB file server with planted sensitive data | Post-exploitation loot |
| `redteam-jumpbox` | SSH bastion host with agent forwarding | Lateral movement |
| `redteam-ftp` | FTP with anonymous access and weak credentials | Enumeration target |
| `redteam-mysql` | MySQL with sensitive data and weak root password | Data exfiltration |
| `redteam-wiki` | DokuWiki with internal docs exposing credentials | OSINT target |
| `redteam-ticketing` | IT ticketing system with credential leaks in tickets | OSINT target |

### Infrastructure

| Image | Description |
|-------|-------------|
| `samba-dc` | Samba Active Directory domain controller (ARM-compatible alternative to Windows AD) |

### Architecture Support

Most images support both `x86_64` and `arm64`. Exceptions noted in each image's `image.yaml`.

---

## Scenarios

Scenarios are standalone event timelines (MSELs) that can be layered onto any compatible blueprint. They define inject sequences, expected participant actions, and evaluation criteria.

| Scenario | Description |
|----------|-------------|
| `apt-intrusion` | Advanced persistent threat intrusion simulation |
| `ransomware-attack` | Ransomware deployment and response exercise |
| `insider-threat` | Insider threat detection and investigation |
| `incident-response-drill` | Structured IR drill with timed injects |

---

## Repository Structure

```
cyroid-catalog/
├── catalog.yaml              # Catalog metadata (name, version, maintainer)
├── index.json                # Auto-generated index (checksums, tags, dependencies)
├── blueprints/               # Self-contained range packages
│   ├── ics-power-grid-defense-lab/
│   │   ├── blueprint.yaml    # Network topology, VM definitions, scoring
│   │   ├── content.json      # Walkthrough slides and commands
│   │   └── README.md
│   ├── red-team-training-lab/
│   ├── red-team-training-lab-v2/
│   └── red-team-training-lab-v3/
├── images/                   # Docker image projects
│   ├── ics-plc-sim/
│   │   ├── Dockerfile
│   │   ├── image.yaml        # Name, tag, arch, category metadata
│   │   ├── entrypoint.sh     # Gateway routing + service startup
│   │   ├── plc_sim.py        # PLC simulator application
│   │   └── registers/        # Per-role register map JSON files
│   ├── kali-attack/
│   └── ...                   # 18 images total
├── base-images/              # VM base image definitions (YAML references)
│   ├── linux/                # Kali, Ubuntu, pfSense, Security Onion
│   ├── windows/              # Windows Server 2019/2022/2025, DC 2022
│   ├── network/              # VyOS router
│   └── red-team/             # Specialized red team base images
├── scenarios/                # MSEL timeline definitions
│   ├── manifest.yaml
│   ├── apt-intrusion.yaml
│   └── ...
└── scripts/
    ├── generate-index.py     # Regenerate index.json from catalog contents
    └── build.sh              # Build and push images to GHCR
```

---

## Usage

### In CYROID

Add this repository as a catalog source in your CYROID instance:

1. Go to **Admin Settings > Catalog Sources**
2. Add source URL: `https://github.com/JongoDB/cyroid-catalog.git`
3. Click **Sync** to fetch the catalog index
4. Browse and deploy content from the **Content Catalog** page

### Air-Gapped / Self-Hosted

Clone the repo and configure as a local catalog source:

```bash
git clone https://github.com/JongoDB/cyroid-catalog.git /data/cyroid-catalog
```

Set the catalog source type to `local` with the clone path.

### Building Images Locally

Build all images:

```bash
./scripts/build.sh
```

Build a specific image:

```bash
./scripts/build.sh kali-attack
```

Build and push to a container registry:

```bash
REGISTRY_PREFIX=ghcr.io/your-org ./scripts/build.sh --push
```

### Regenerating the Index

After adding or modifying blueprints, images, or scenarios:

```bash
python scripts/generate-index.py
```

This is also run automatically via GitHub Actions on push to `main`.

---

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build-images.yml` | Push to `images/**`, weekly, manual | Build Docker images, push to GHCR, Trivy vulnerability scan, SBOM generation |
| `regenerate-index.yml` | Push to content dirs on `main`, manual | Regenerate `index.json` and auto-commit |

Image builds support multi-architecture (`linux/amd64`, `linux/arm64`) and run parallel matrix jobs for each discovered Dockerfile.

---

## Anatomy of a Blueprint

A blueprint defines everything needed to provision a training range:

```yaml
# blueprint.yaml
name: my-training-lab
description: "Lab description"

networks:
  - name: dmz
    subnet: "172.16.1.0/24"
    is_isolated: true

vms:
  - hostname: attacker
    base_image_tag: "127.0.0.1:5000/cyroid/kali-attack:latest"
    network_interfaces:
      - network_name: internet
        ip_address: "172.16.0.10"
        is_primary: true
    cpu: 2
    ram_mb: 4096

content:          # Optional: walkthrough slides
msel:             # Optional: scenario timeline
scoring_rubric:   # Optional: evaluation criteria
```

## Anatomy of an Image

Each image directory contains:

```
images/my-image/
├── Dockerfile        # Container build definition
├── image.yaml        # Catalog metadata
├── entrypoint.sh     # Startup script (gateway routing, service init)
└── ...               # Application code, configs, templates
```

`image.yaml` fields:

```yaml
name: my-image
display_name: "My Image"
tag: latest
description: "What this image does"
category: red-team          # ics, red-team, infrastructure
arch: both                  # x86_64, arm64, both
capabilities: []            # NET_ADMIN, NET_RAW, etc.
privileged: false
```

---

## Contributing

To add new content to the catalog, see [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## License

See [LICENSE](LICENSE).

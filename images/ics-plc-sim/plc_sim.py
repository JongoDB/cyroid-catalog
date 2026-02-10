#!/usr/bin/env python3
"""CYROID ICS PLC Simulator - Universal multi-protocol PLC for cyber range training.

Supports Modbus TCP, OPC UA, and EtherNet/IP protocols.
Simulates realistic power grid process values with drift, noise, and physics.
"""

import asyncio
import json
import logging
import os
import random
import signal
import sys
import time
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(name)s] %(levelname)s: %(message)s")
log = logging.getLogger("plc-sim")

# Hostname-based auto-configuration for CYROID ICS Power Grid Defense Lab.
# If PLC_PROTOCOL env var is not explicitly set, detect config from hostname.
HOSTNAME_CONFIG = {
    "plc-sub-a":  {"protocol": "modbus", "role": "substation_protection", "name": "Substation-A Protection Relay"},
    "plc-sub-b":  {"protocol": "modbus", "role": "substation_breaker",    "name": "Substation-B Breaker Control"},
    "plc-gen":    {"protocol": "enip",   "role": "turbine_governor",      "name": "Turbine Governor"},
    "plc-load":   {"protocol": "modbus", "role": "load_management",       "name": "Load Management"},
    "plc-safety": {"protocol": "opcua",  "role": "safety_sis",            "name": "Safety Instrumented System"},
    "rtu-dist":   {"protocol": "modbus", "role": "distribution_rtu",      "name": "Distribution RTU"},
}

def _auto_config():
    """Resolve PLC config from env vars, falling back to hostname detection."""
    import socket
    hostname = socket.gethostname()
    auto = HOSTNAME_CONFIG.get(hostname, {})
    protocol = os.environ.get("PLC_PROTOCOL", auto.get("protocol", "modbus")).lower()
    name = os.environ.get("PLC_NAME", auto.get("name", "PLC-001"))
    role = os.environ.get("PLC_ROLE", auto.get("role", "substation_breaker"))
    port = os.environ.get("PLC_PORT", "")
    if auto:
        log.info(f"Auto-configured from hostname '{hostname}': protocol={protocol}, role={role}")
    return protocol, name, role, port

PROTOCOL, PLC_NAME, PLC_ROLE, PLC_PORT = _auto_config()

REGISTER_DIR = Path("/app/registers")


def load_register_map():
    """Load the register map JSON for this PLC role."""
    map_file = REGISTER_DIR / f"{PLC_ROLE}.json"
    if not map_file.exists():
        log.warning(f"No register map for role '{PLC_ROLE}', using default")
        map_file = REGISTER_DIR / "substation_breaker.json"
    with open(map_file) as f:
        return json.load(f)


class ProcessSimulator:
    """Simulates physical process values with drift and noise."""

    def __init__(self, register_map):
        self.registers = {}
        self.config = {}
        for reg in register_map.get("holding_registers", []):
            addr = reg["address"]
            self.registers[addr] = reg["default"]
            self.config[addr] = reg

    def update(self):
        """Apply realistic process variation to register values."""
        for addr, cfg in self.config.items():
            if not cfg.get("writable", False) and cfg.get("simulate", True):
                base = cfg["default"]
                noise = cfg.get("noise", 0.01)
                current = self.registers[addr]
                # Mean-reverting random walk
                drift = (base - current) * 0.1 + random.gauss(0, base * noise)
                new_val = current + drift
                # Clamp to min/max
                min_val = cfg.get("min", base * 0.5)
                max_val = cfg.get("max", base * 1.5)
                self.registers[addr] = max(min_val, min(max_val, new_val))


# ============================================================
# MODBUS TCP SERVER
# ============================================================
async def run_modbus(register_map, port):
    from pymodbus.datastore import (
        ModbusSequentialDataBlock,
        ModbusSlaveContext,
        ModbusServerContext,
    )
    from pymodbus.server import StartAsyncTcpServer

    sim = ProcessSimulator(register_map)

    # Build initial register values (Modbus addresses are 0-based in pymodbus)
    max_addr = max(sim.registers.keys(), default=0) + 10
    hr_values = [0] * (max_addr + 1)
    for addr, val in sim.registers.items():
        hr_values[addr] = int(val)

    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [0] * 100),
        co=ModbusSequentialDataBlock(0, [0] * 100),
        hr=ModbusSequentialDataBlock(0, hr_values),
        ir=ModbusSequentialDataBlock(0, [0] * 100),
    )
    context = ModbusServerContext(slaves=store, single=True)

    # Background task to update process values
    async def process_loop():
        while True:
            await asyncio.sleep(1)
            sim.update()
            for addr, val in sim.registers.items():
                store.setValues(3, addr, [int(val)])  # FC3 = holding registers

    asyncio.create_task(process_loop())

    log.info(f"Modbus TCP server starting on 0.0.0.0:{port}")
    log.info(f"Holding registers: {len(sim.registers)} points")
    await StartAsyncTcpServer(context=context, address=("0.0.0.0", port))


# ============================================================
# OPC UA SERVER
# ============================================================
async def run_opcua(register_map, port):
    from asyncua import Server, ua

    server = Server()
    await server.init()
    server.set_endpoint(f"opc.tcp://0.0.0.0:{port}/cyroid/plc")
    server.set_server_name(f"CYROID {PLC_NAME}")

    idx = await server.register_namespace("http://cyroid.io/ics/plc")

    sim = ProcessSimulator(register_map)

    # Create OPC UA nodes from register map
    plc_obj = await server.nodes.objects.add_object(idx, PLC_NAME)
    ua_vars = {}
    for addr, cfg in sim.config.items():
        var = await plc_obj.add_variable(
            idx, cfg["name"], float(sim.registers[addr]),
            varianttype=ua.VariantType.Double
        )
        if cfg.get("writable", False):
            await var.set_writable()
        ua_vars[addr] = var

    async with server:
        log.info(f"OPC UA server starting on opc.tcp://0.0.0.0:{port}/cyroid/plc")
        log.info(f"Nodes: {len(ua_vars)} variables under '{PLC_NAME}'")
        while True:
            await asyncio.sleep(1)
            sim.update()
            for addr, var in ua_vars.items():
                await var.write_value(float(sim.registers[addr]))


# ============================================================
# ETHERNET/IP (CIP) SERVER
# ============================================================
async def run_enip(register_map, port):
    """Run EtherNet/IP server using cpppo."""
    import subprocess

    sim = ProcessSimulator(register_map)

    # Build cpppo tag definitions from register map
    tags = []
    for addr, cfg in sim.config.items():
        tag_name = cfg["name"].replace(" ", "_").replace("/", "_")
        tags.append(f"{tag_name}=REAL")

    tag_str = " ".join(tags)
    cmd = f"python3 -m cpppo.server.enip --address 0.0.0.0:{port} {tag_str}"

    log.info(f"EtherNet/IP server starting on 0.0.0.0:{port}")
    log.info(f"Tags: {len(tags)}")

    proc = await asyncio.create_subprocess_shell(
        cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )

    # Give server time to start
    await asyncio.sleep(2)

    # Background loop to update tag values via cpppo client
    while True:
        await asyncio.sleep(2)
        sim.update()
        # Update tags via client write
        for addr, cfg in sim.config.items():
            tag_name = cfg["name"].replace(" ", "_").replace("/", "_")
            val = sim.registers[addr]
            try:
                write_proc = await asyncio.create_subprocess_shell(
                    f"python3 -m cpppo.server.enip.client --address 127.0.0.1:{port} '{tag_name}=(REAL){val}'",
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                )
                await write_proc.wait()
            except Exception:
                pass


# ============================================================
# MAIN
# ============================================================
def get_port():
    if PLC_PORT:
        return int(PLC_PORT)
    defaults = {"modbus": 502, "opcua": 4840, "enip": 44818}
    return defaults.get(PROTOCOL, 502)


async def main():
    register_map = load_register_map()
    port = get_port()

    log.info(f"Starting {PLC_NAME} ({PLC_ROLE}) with {PROTOCOL} on port {port}")

    runners = {
        "modbus": run_modbus,
        "opcua": run_opcua,
        "enip": run_enip,
    }

    runner = runners.get(PROTOCOL)
    if not runner:
        log.error(f"Unknown protocol: {PROTOCOL}. Use: modbus, opcua, enip")
        sys.exit(1)

    await runner(register_map, port)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        log.info("Shutting down PLC simulator")

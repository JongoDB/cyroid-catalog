#!/usr/bin/env python3
"""CYROID ICS SCADA HMI - Web-based dashboard that polls PLCs and displays process values."""

import json
import logging
import os
import threading
import time

from flask import Flask, jsonify, render_template

logging.basicConfig(level=logging.INFO, format="%(asctime)s [HMI] %(levelname)s: %(message)s")
log = logging.getLogger("hmi")

app = Flask(__name__, template_folder="/app/templates")

# Hostname-based auto-configuration for CYROID ICS Power Grid Defense Lab.
# If PLC_TARGETS env var is not set, detect config from hostname.
HOSTNAME_CONFIG = {
    "hmi-sub": {
        "name": "Substation HMI",
        "role": "substation",
        "targets": [
            {"name": "plc-sub-a", "host": "172.16.5.10", "port": 502, "protocol": "modbus"},
            {"name": "plc-sub-b", "host": "172.16.5.20", "port": 502, "protocol": "modbus"},
        ],
    },
    "hmi-gen": {
        "name": "Generation HMI",
        "role": "generation",
        "targets": [
            {"name": "plc-gen",  "host": "172.16.5.30", "port": 44818, "protocol": "enip"},
            {"name": "plc-load", "host": "172.16.5.40", "port": 502,   "protocol": "modbus"},
        ],
    },
    "hmi-grid": {
        "name": "Grid Overview HMI",
        "role": "grid",
        "targets": [
            {"name": "plc-sub-a",  "host": "172.16.5.10", "port": 502,   "protocol": "modbus"},
            {"name": "plc-sub-b",  "host": "172.16.5.20", "port": 502,   "protocol": "modbus"},
            {"name": "plc-gen",    "host": "172.16.5.30", "port": 44818, "protocol": "enip"},
            {"name": "plc-load",   "host": "172.16.5.40", "port": 502,   "protocol": "modbus"},
            {"name": "plc-safety", "host": "172.16.5.50", "port": 4840,  "protocol": "opcua"},
            {"name": "rtu-dist",   "host": "172.16.5.60", "port": 502,   "protocol": "modbus"},
        ],
    },
}

def _auto_config():
    """Hostname auto-config takes priority over Dockerfile ENV defaults."""
    import socket
    hostname = socket.gethostname()
    auto = HOSTNAME_CONFIG.get(hostname, {})
    if auto:
        # Hostname match — use auto-config (ignore Dockerfile ENV defaults)
        targets = auto["targets"]
        name = auto["name"]
        role = auto["role"]
        log.info(f"Auto-configured from hostname '{hostname}': role={role}, targets={len(targets)} PLCs")
    else:
        # No hostname match — fall back to env vars
        targets_env = os.environ.get("PLC_TARGETS", "[]")
        targets = json.loads(targets_env) if targets_env else []
        name = os.environ.get("HMI_NAME", "HMI-001")
        role = os.environ.get("HMI_ROLE", "substation")
    return name, role, targets

HMI_NAME, HMI_ROLE, PLC_TARGETS = _auto_config()

# Shared state for latest PLC readings
plc_data = {}
plc_data_lock = threading.Lock()


def poll_modbus(target):
    """Poll a Modbus TCP PLC and return register values."""
    try:
        from pymodbus.client import ModbusTcpClient
        client = ModbusTcpClient(target["host"], port=target.get("port", 502), timeout=3)
        if client.connect():
            for count in (50, 40, 20, 10):
                result = client.read_holding_registers(0, count, slave=1)
                if not result.isError():
                    client.close()
                    return {str(i): v for i, v in enumerate(result.registers)}
            client.close()
    except Exception as e:
        log.debug(f"Modbus poll error for {target['host']}: {e}")
    return None


def poll_opcua(target):
    """Poll an OPC UA server and return node values."""
    try:
        import asyncio
        from asyncua import Client

        async def _read():
            url = f"opc.tcp://{target['host']}:{target.get('port', 4840)}/cyroid/plc"
            async with Client(url=url) as client:
                root = client.nodes.objects
                children = await root.get_children()
                values = {}
                for child in children:
                    try:
                        name = await child.read_browse_name()
                        sub_children = await child.get_children()
                        for var in sub_children:
                            var_name = await var.read_browse_name()
                            val = await var.read_value()
                            values[var_name.Name] = round(float(val), 2)
                    except Exception:
                        pass
                return values

        return asyncio.run(_read())
    except Exception as e:
        log.debug(f"OPC UA poll error for {target['host']}: {e}")
    return None


ENIP_TAGS = [
    "Turbine_Speed_RPM", "Generator_Output_MW", "Generator_Voltage_kV",
    "Generator_Current_A", "Frequency_Hz", "Steam_Pressure_PSI",
    "Steam_Temperature_C", "Governor_Position_Pct", "Exciter_Voltage_V",
    "Bearing_Temperature_C", "Lube_Oil_Pressure_PSI", "Vibration_mm_s",
    "Breaker_Status", "Sync_Check_Status", "Auto_Voltage_Reg_Mode",
]


def poll_enip(target):
    """Poll an EtherNet/IP device using cpppo client."""
    try:
        import subprocess
        result = subprocess.run(
            ["python3", "-m", "cpppo.server.enip.client",
             "--address", f"{target['host']}:{target.get('port', 44818)}",
             "--print"] + ENIP_TAGS,
            capture_output=True, text=True, timeout=10
        )
        if result.stdout.strip():
            data = {}
            for line in result.stdout.strip().split("\n"):
                if "==" in line:
                    parts = line.split("==")
                    tag = parts[0].strip()
                    val_str = parts[1].strip().split(":")[0].strip()
                    val_str = val_str.strip("[] ")
                    try:
                        data[tag] = round(float(val_str), 2)
                    except ValueError:
                        data[tag] = val_str
            return data if data else None
    except Exception as e:
        log.debug(f"EtherNet/IP poll error for {target['host']}: {e}")
    return None


POLLERS = {
    "modbus": poll_modbus,
    "opcua": poll_opcua,
    "enip": poll_enip,
}


def polling_loop():
    """Background thread that polls all PLCs every 2 seconds."""
    while True:
        for target in PLC_TARGETS:
            proto = target.get("protocol", "modbus")
            poller = POLLERS.get(proto)
            if poller:
                data = poller(target)
                if data:
                    with plc_data_lock:
                        plc_data[target.get("name", target["host"])] = {
                            "registers": data,
                            "protocol": proto,
                            "host": target["host"],
                            "last_update": time.time(),
                        }
        time.sleep(2)


@app.route("/")
def index():
    with plc_data_lock:
        data_copy = dict(plc_data)
    return render_template("dashboard.html",
                           hmi_name=HMI_NAME, hmi_role=HMI_ROLE,
                           plc_data=data_copy, plc_targets=PLC_TARGETS)


@app.route("/api/data")
def api_data():
    with plc_data_lock:
        return jsonify(plc_data)


@app.route("/api/health")
def health():
    return jsonify({"status": "ok", "hmi": HMI_NAME, "role": HMI_ROLE})


if __name__ == "__main__":
    if PLC_TARGETS:
        t = threading.Thread(target=polling_loop, daemon=True)
        t.start()
        log.info(f"Polling {len(PLC_TARGETS)} PLCs")
    else:
        log.warning("No PLC_TARGETS configured - running in demo mode")

    log.info(f"HMI '{HMI_NAME}' ({HMI_ROLE}) starting on port 8080")
    app.run(host="0.0.0.0", port=8080, debug=False)

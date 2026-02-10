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

HMI_NAME = os.environ.get("HMI_NAME", "HMI-001")
HMI_ROLE = os.environ.get("HMI_ROLE", "substation")
PLC_TARGETS = json.loads(os.environ.get("PLC_TARGETS", "[]"))

# Shared state for latest PLC readings
plc_data = {}
plc_data_lock = threading.Lock()


def poll_modbus(target):
    """Poll a Modbus TCP PLC and return register values."""
    try:
        from pymodbus.client import ModbusTcpClient
        client = ModbusTcpClient(target["host"], port=target.get("port", 502), timeout=3)
        if client.connect():
            result = client.read_holding_registers(0, 50, slave=1)
            client.close()
            if not result.isError():
                return {str(i): v for i, v in enumerate(result.registers)}
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


def poll_enip(target):
    """Poll an EtherNet/IP device."""
    # Simplified - reads tags via cpppo client
    try:
        import subprocess
        result = subprocess.run(
            ["python3", "-m", "cpppo.server.enip.client",
             "--address", f"{target['host']}:{target.get('port', 44818)}",
             "--print", "scada[0-9]"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            return {"raw": result.stdout.strip()}
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
                            "values": data,
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

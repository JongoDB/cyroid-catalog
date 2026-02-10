#!/usr/bin/env python3
"""CYROID ICS Historian - Polls PLCs and stores time-series process data."""

import json
import logging
import os
import sqlite3
import threading
import time

from flask import Flask, jsonify, request

logging.basicConfig(level=logging.INFO, format="%(asctime)s [HIST] %(levelname)s: %(message)s")
log = logging.getLogger("historian")

app = Flask(__name__)

PLC_TARGETS = json.loads(os.environ.get("PLC_TARGETS", "[]"))
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "5"))
DB_PATH = os.environ.get("DB_PATH", "/data/historian.db")


def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS process_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            plc_name TEXT NOT NULL,
            register_name TEXT NOT NULL,
            value REAL NOT NULL
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_ts ON process_data(timestamp)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_plc ON process_data(plc_name)")
    conn.commit()
    conn.close()


def poll_modbus(target):
    try:
        from pymodbus.client import ModbusTcpClient
        client = ModbusTcpClient(target["host"], port=target.get("port", 502), timeout=3)
        if client.connect():
            result = client.read_holding_registers(0, 50, slave=1)
            client.close()
            if not result.isError():
                return {str(i): v for i, v in enumerate(result.registers)}
    except Exception as e:
        log.debug(f"Poll error {target['host']}: {e}")
    return None


def store_data(plc_name, values):
    try:
        conn = sqlite3.connect(DB_PATH)
        ts = time.time()
        rows = [(ts, plc_name, k, float(v)) for k, v in values.items()]
        conn.executemany(
            "INSERT INTO process_data (timestamp, plc_name, register_name, value) VALUES (?,?,?,?)",
            rows
        )
        conn.commit()
        conn.close()
    except Exception as e:
        log.error(f"DB error: {e}")


def polling_loop():
    while True:
        for target in PLC_TARGETS:
            data = poll_modbus(target)
            if data:
                store_data(target.get("name", target["host"]), data)
        time.sleep(POLL_INTERVAL)


@app.route("/")
def index():
    return """<html><head><title>CYROID Historian</title></head>
    <body style="background:#1a1a2e;color:#e0e0e0;font-family:monospace;padding:20px">
    <h1 style="color:#00d4ff">CYROID Process Historian</h1>
    <p>API Endpoints:</p>
    <ul>
    <li><a href="/api/latest" style="color:#4caf50">/api/latest</a> - Latest values per PLC</li>
    <li><a href="/api/history?plc=all&minutes=60" style="color:#4caf50">/api/history?plc=NAME&minutes=60</a> - Historical data</li>
    <li><a href="/api/plcs" style="color:#4caf50">/api/plcs</a> - List of PLCs</li>
    </ul></body></html>"""


@app.route("/api/latest")
def api_latest():
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("""
        SELECT plc_name, register_name, value, MAX(timestamp) as ts
        FROM process_data GROUP BY plc_name, register_name
    """).fetchall()
    conn.close()
    result = {}
    for plc, reg, val, ts in rows:
        if plc not in result:
            result[plc] = {}
        result[plc][reg] = {"value": val, "timestamp": ts}
    return jsonify(result)


@app.route("/api/history")
def api_history():
    plc = request.args.get("plc", "all")
    minutes = int(request.args.get("minutes", "60"))
    since = time.time() - (minutes * 60)
    conn = sqlite3.connect(DB_PATH)
    if plc == "all":
        rows = conn.execute(
            "SELECT timestamp, plc_name, register_name, value FROM process_data WHERE timestamp > ? ORDER BY timestamp",
            (since,)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT timestamp, plc_name, register_name, value FROM process_data WHERE plc_name=? AND timestamp > ? ORDER BY timestamp",
            (plc, since)
        ).fetchall()
    conn.close()
    return jsonify([{"ts": r[0], "plc": r[1], "reg": r[2], "val": r[3]} for r in rows])


@app.route("/api/plcs")
def api_plcs():
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT DISTINCT plc_name FROM process_data").fetchall()
    conn.close()
    return jsonify([r[0] for r in rows])


if __name__ == "__main__":
    init_db()
    if PLC_TARGETS:
        t = threading.Thread(target=polling_loop, daemon=True)
        t.start()
        log.info(f"Polling {len(PLC_TARGETS)} PLCs every {POLL_INTERVAL}s")
    log.info("Historian API starting on port 8080")
    app.run(host="0.0.0.0", port=8080, debug=False)

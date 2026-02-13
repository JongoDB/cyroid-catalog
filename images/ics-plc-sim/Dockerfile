# CYROID ICS PLC Simulator
# Universal PLC simulator supporting Modbus TCP, OPC UA, and EtherNet/IP
#
# Environment Variables:
#   PLC_PROTOCOL  - modbus | opcua | enip (default: modbus)
#   PLC_NAME      - Display name (default: PLC-001)
#   PLC_ROLE      - substation_protection | substation_breaker | turbine_governor |
#                   load_management | safety_sis | distribution_rtu
#   PLC_PORT      - Override default protocol port
#
# Build: docker build -t cyroid/ics-plc-sim:latest .
# Run:   docker run -d -e PLC_PROTOCOL=modbus -e PLC_ROLE=substation_breaker cyroid/ics-plc-sim:latest

FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        iproute2 \
        iputils-ping \
        procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    pymodbus==3.7.4 \
    asyncua==1.1.5 \
    cpppo==4.4.2 \
    && python3 -c "\
import pathlib, re; \
p = pathlib.Path('/usr/local/lib/python3.12/site-packages/cpppo/misc.py'); \
src = p.read_text(); \
patched = re.sub( \
    r'(def change_function\(function, \*\*kwds\):)\n.*?(?=\nlogging\.)', \
    r'\1\n    return function\n', \
    src, count=1, flags=re.DOTALL); \
p.write_text(patched); \
print('Patched cpppo/misc.py change_function for Python 3.12+')"

COPY plc_sim.py /app/plc_sim.py
COPY registers/ /app/registers/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PLC_PROTOCOL=modbus \
    PLC_NAME=PLC-001 \
    PLC_ROLE=substation_breaker \
    PLC_PORT=""

EXPOSE 502 4840 44818

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "/app/plc_sim.py"]

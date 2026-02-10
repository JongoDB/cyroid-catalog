# CYROID ICS SCADA HMI Dashboard
# Web-based HMI that polls PLCs and renders real-time process displays
#
# Environment Variables:
#   HMI_NAME      - Display name (default: HMI-001)
#   HMI_ROLE      - substation | generation | grid (default: substation)
#   PLC_TARGETS   - JSON array of PLC connections, e.g.:
#                   [{"host":"172.16.5.10","port":502,"protocol":"modbus","name":"plc-sub-a"}]
#
# Build: docker build -t cyroid/ics-hmi:latest .
# Run:   docker run -d -p 8080:8080 -e HMI_ROLE=substation cyroid/ics-hmi:latest

FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        iproute2 \
        iputils-ping \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    flask==3.1.0 \
    pymodbus==3.7.4 \
    asyncua==1.1.5 \
    cpppo==4.4.2

COPY hmi_app.py /app/hmi_app.py
COPY templates/ /app/templates/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV HMI_NAME=HMI-001 \
    HMI_ROLE=substation \
    PLC_TARGETS="[]"

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "/app/hmi_app.py"]

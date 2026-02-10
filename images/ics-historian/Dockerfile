# CYROID ICS Process Data Historian
# Polls PLCs and stores time-series process data
#
# Environment Variables:
#   PLC_TARGETS    - JSON array of PLC connections
#   POLL_INTERVAL  - Seconds between polls (default: 5)
#   DB_PATH        - SQLite database path (default: /data/historian.db)
#
# Build: docker build -t cyroid/ics-historian:latest .
# Run:   docker run -d -p 8080:8080 cyroid/ics-historian:latest

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

COPY historian.py /app/historian.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p /data

ENV PLC_TARGETS="[]" \
    POLL_INTERVAL=5 \
    DB_PATH=/data/historian.db

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "/app/historian.py"]

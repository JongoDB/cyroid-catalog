# c2-operator: Sliver C2 server with auto-start HTTP listener
# Based on the sliver service from https://github.com/jongodb/sliver-weather

FROM golang:1.22-bookworm

ARG SLIVER_VERSION=v1.7.1
ARG SLIVER_UID=999
ARG SLIVER_GID=999

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl jq openssl \
      libpcap0.8 libsqlite3-0 libxml2 libxslt1.1 \
      build-essential pkg-config zip unzip nasm protobuf-compiler \
      mingw-w64 binutils-mingw-w64 g++-mingw-w64 \
      net-tools iputils-ping iproute2 \
      gosu \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${SLIVER_GID} sliver \
 && useradd -r -u ${SLIVER_UID} -g sliver -m -d /home/sliver sliver

# Download Sliver server (arch-aware)
RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    SLIVER_URL=$(curl -fsSL "https://api.github.com/repos/BishopFox/sliver/releases/tags/${SLIVER_VERSION}" \
      | jq -r ".assets[] | select(.name == \"sliver-server_linux-${ARCH}\") | .browser_download_url"); \
    if [ -z "$SLIVER_URL" ] || [ "$SLIVER_URL" = "null" ]; then \
      echo "ERROR: No Sliver server binary for linux-${ARCH} at ${SLIVER_VERSION}"; exit 1; \
    fi; \
    curl -fSL -o /opt/sliver-server "$SLIVER_URL"; \
    chmod +x /opt/sliver-server

RUN mkdir -p /home/sliver/.sliver /home/sliver/builds \
 && chown -R sliver:sliver /home/sliver

ENV SLIVER_HTTP_PORT=8080
ENV SLIVER_AUTOSTART_HTTP=1

# Entrypoint: fix ownership, auto-start HTTP listener, run sliver-server
RUN printf '%s\n' \
'#!/bin/sh' \
'set -e' \
'SLIVER_HOME="/home/sliver"' \
': "${SLIVER_HTTP_PORT:=8080}"' \
': "${SLIVER_AUTOSTART_HTTP:=1}"' \
'mkdir -p "$SLIVER_HOME/.sliver" "$SLIVER_HOME/builds" || true' \
'chown -R sliver:sliver "$SLIVER_HOME" || true' \
'' \
'if [ "$SLIVER_AUTOSTART_HTTP" = "1" ]; then' \
'  ( sleep 3; gosu sliver /opt/sliver-server http --lhost 0.0.0.0 --lport "$SLIVER_HTTP_PORT" || true ) & ' \
'fi' \
'' \
'echo "[entrypoint] launching sliver-server (foreground) ..."' \
'exec gosu sliver /opt/sliver-server' \
> /usr/local/bin/entrypoint.sh \
 && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/sliver
EXPOSE 80 443 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

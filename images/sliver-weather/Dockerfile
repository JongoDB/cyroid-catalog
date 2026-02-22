FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SLIVER_WEATHER_REPO=https://github.com/jongodb/sliver-weather.git

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    curl \
    git \
    openssl \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone sliver-weather repo
RUN git clone ${SLIVER_WEATHER_REPO} /opt/sliver-weather

# Build the weather app
WORKDIR /opt/sliver-weather/weather-app
RUN npm install && npm run build 2>/dev/null || true

# Install jq for JSON parsing, then download Sliver server (arch-aware)
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/* \
    && ARCH=$(uname -m | sed "s/x86_64/amd64/" | sed "s/aarch64/arm64/") \
    && SLIVER_URL=$(curl -s https://api.github.com/repos/BishopFox/sliver/releases/latest \
       | jq -r ".assets[] | select(.name | test(\"sliver-server_linux-${ARCH}\")) | .browser_download_url" | head -1) \
    && curl -fSL -o /usr/local/bin/sliver-server "$SLIVER_URL" \
    && chmod +x /usr/local/bin/sliver-server

# Generate self-signed TLS certs for nginx
RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout /etc/nginx/ssl/server.key \
       -out /etc/nginx/ssl/server.crt \
       -subj "/C=US/ST=State/L=City/O=WeatherCorp/CN=weather.local"

# Copy config files
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports: HTTP, HTTPS, Sliver mTLS, Sliver gRPC operator
EXPOSE 80 443 31337 31338

WORKDIR /opt/sliver-weather
ENTRYPOINT ["/entrypoint.sh"]

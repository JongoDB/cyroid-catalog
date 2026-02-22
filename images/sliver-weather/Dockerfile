# sliver-weather: Weather frontend (nginx + Node.js Express) — NO Sliver C2
# Combines the nginx and weather services from the sliver-weather repo
# into a single container managed by supervisord.
#
# Nginx proxies C2 traffic (/api/news/) to an external Sliver server
# specified by SLIVER_C2_HOST and SLIVER_HTTP_PORT env vars.

FROM node:20-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
RUN git clone https://github.com/jongodb/sliver-weather.git /tmp/repo
COPY . /tmp/repo-check
RUN cp /tmp/repo/weather/package.json /tmp/repo/weather/server.js ./
RUN cp -r /tmp/repo/weather/src ./src 2>/dev/null || true
RUN cp -r /tmp/repo/weather/public ./public 2>/dev/null || true
RUN cp /tmp/repo/weather/vite.config.* ./ 2>/dev/null || true
RUN cp /tmp/repo/weather/index.html ./ 2>/dev/null || true
RUN cp /tmp/repo/weather/tsconfig*.json ./ 2>/dev/null || true
RUN cp /tmp/repo/weather/postcss.config.* ./ 2>/dev/null || true
RUN cp /tmp/repo/weather/tailwind.config.* ./ 2>/dev/null || true
RUN npm ci || npm install
RUN npm run build

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOMAIN=weather-server
ENV USE_TLS=false
ENV SLIVER_C2_HOST=10.10.2.30
ENV SLIVER_HTTP_PORT=8080
ENV SLIVER_C2_PATH=/api/news/
ENV NGINX_HTTP_PORT=80
ENV WEATHER_APP_PORT=5000

# Install nginx, supervisor, Node.js
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    curl \
    gettext-base \
    ca-certificates \
    gnupg \
    net-tools \
    iputils-ping \
    iproute2 \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy built weather app from builder stage
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/server.js ./

# Create builds directory (for implant delivery)
RUN mkdir -p /app/builds

# Remove default nginx config
RUN rm -f /etc/nginx/sites-enabled/default

# Copy our configs
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

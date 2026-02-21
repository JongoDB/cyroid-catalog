FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOMAIN=weather-server
ENV USE_TLS=false
ENV SLIVER_C2_HOST=10.10.2.30
ENV SLIVER_HTTP_PORT=8080
ENV SLIVER_C2_PATH=/api/news/
ENV NGINX_HTTP_PORT=80
ENV WEATHER_APP_PORT=3001

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nginx \
    supervisor \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    iputils-ping \
    iproute2 \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker (for operational use within the range)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Clone the sliver-weather repo
RUN git clone https://github.com/jongodb/sliver-weather.git /opt/sliver-weather

# Build the weather frontend
WORKDIR /opt/sliver-weather/weather
RUN npm install && npm run build

# Configure nginx as reverse proxy
# - / -> weather frontend (local Express on port 3001)
# - /api/news/ -> C2 server (sliver on c2-net)
# - /api/download/ -> weather app download endpoint
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Supervisor to manage nginx + weather app
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Entrypoint script to render nginx config with env vars
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

WORKDIR /opt/sliver-weather
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

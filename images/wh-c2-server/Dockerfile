FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SLIVER_HTTP_PORT=8080

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    iputils-ping \
    iproute2 \
    vim \
    mingw-w64 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && rm -rf /var/lib/apt/lists/*

# Install Sliver C2
RUN curl https://sliver.sh/install | bash

# Clone the sliver-weather repo (for implant builds directory structure)
RUN git clone https://github.com/jongodb/sliver-weather.git /opt/sliver-weather

# Create builds directory for implants
RUN mkdir -p /home/sliver/builds

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080 31337

WORKDIR /home/sliver
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]

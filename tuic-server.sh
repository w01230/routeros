#!/bin/bash

# Swith to home
cd

# Install tuic
curl -Lo tuic-server https://github.com/EAimTY/tuic/releases/latest/download/tuic-server-1.0.0-x86_64-unknown-linux-gnu && chmod +x tuic-server && mv -f tuic-server /usr/local/bin/
mkdir -p /etc/tuic/

# Install configuration
server="{
    "server": "0.0.0.0:10443",
    "users": {
        "uuid": "psk"
    },
    "certificate": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/n.0.xyz/n.0.xyz.crt",
    "private_key": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/n.0.xyz/n.0.xyz.key",
    "congestion_control": "bbr",
    "alpn": ["h3"],
    "log_level": "warn"
}"
echo -e "$server\n" | tee /etc/tuic/tuic-server.json > /dev/null

# Install service
service="[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/tuic-server -c /etc/tuic/tuic-server.json
Restart=on-failure
RestartSec=10
LimitNPROC=512
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target"
echo -e "$service\n" |  tee /etc/systemd/system/tuic.service > /dev/null

# Enable service
systemctl enable tuic.service
#systemctl start tuic.service

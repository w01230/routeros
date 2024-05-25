#!/bin/bash

# Install caddy
curl -s https://api.github.com/repos/klzgrad/forwardproxy/releases/latest | grep browser_download_url | cut -d '"' -f 4 |  xargs wget -qi -
xz -d caddy-forwardproxy-naive.xz
tar -xf caddy-forwardproxy-naive.tar
cp caddy-forwardproxy-naive/caddy /usr/bin/
mkdir -p /etc/caddy

# Install configuration
server=":443, domain.com"
tls="tls m@domain.com"
route="route {
        forward_proxy {
                basic_auth 0x01230 psk
                hide_ip
                hide_via
                probe_resistance
        }
        reverse_proxy https://archlinux.org {
                header_up Host {upstream_hostport}
                header_up X-Forwarded-Host {host}
        }
}"
echo -e "$server\n$tls\n$route\n" | tee /etc/caddy/Caddyfile > /dev/null

# Install service
service="[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target"
echo -e "$service\n" |  tee /etc/systemd/system/caddy.service > /dev/null

# Enable service
systemctl enable caddy.service
systemctl start caddy.service

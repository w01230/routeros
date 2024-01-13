#!/bin/bash

# Install dependencies based on the Linux distribution
if cat /etc/*-release | grep -q -E -i "debian|ubuntu|armbian|deepin|mint"; then
     apt-get install wget unzip dpkg -y
elif cat /etc/*-release | grep -q -E -i "centos|red hat|redhat"; then
     yum install wget unzip dpkg -y
elif cat /etc/*-release | grep -q -E -i "arch|manjaro"; then
     pacman -S wget dpkg unzip --noconfirm
elif cat /etc/*-release | grep -q -E -i "fedora"; then
     dnf install wget unzip dpkg -y
fi

# Swith to home
cd

# Install go
wget https://go.dev/dl/go1.20.7.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile
source $HOME/.profile

# Install caddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
       ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
cp caddy /usr/bin/
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

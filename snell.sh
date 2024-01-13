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

cd
ARCHITECTURE=$(uname -m)
wget -c https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
unzip -o snell-server-v4.0.1-linux-amd64.zip

# Create systemd service
echo -e "[Unit]\nDescription=snell server\n[Service]\nUser=$(whoami)\nExecStart=/usr/bin/snell-server -c /etc/snell/snell-server.conf\nRestart=always\n[Install]\nWantedBy=multi-user.target" |  tee /etc/systemd/system/snell.service > /dev/null
echo "y" |  ./snell-server
mkdir -p /etc/snell/
mv -f snell-server.conf /etc/snell/
mv -f snell-server /usr/bin/
systemctl daemon-reload
systemctl start snell
systemctl enable snell

# Print profile
echo
echo "Copy the following line to surge"
echo "$(curl -s ipinfo.io/city) = snell, $(curl -s ipinfo.io/ip), $(cat /etc/snell/snell-server.conf | grep -i listen | cut --delimiter=':' -f2),psk=$(grep 'psk' /etc/snell/snell-server.conf | cut -d= -f2 | tr -d ' '), version=4, tfo=true, reuse=true"

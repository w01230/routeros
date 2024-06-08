#!/bin/bash

# 下载并安装 Snell 最新版本
SNELL_URL="https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip"
wget $SNELL_URL -O snell.zip
unzip snell.zip

# 获取解压后的文件夹名称
SNELL_DIR=$(unzip -Z1 snell.zip | head -1 | cut -d '/' -f1)

# 移动 snell-server 可执行文件到 /usr/local/bin/
sudo mv $SNELL_DIR/snell-server /usr/local/bin/
rm -r $SNELL_DIR
rm snell.zip

# 生成随机密码
SNELL_PASSWORD=$(openssl rand -base64 16)

# 创建 Snell 配置文件目录
sudo mkdir -p /etc/snell

# 创建 Snell 配置文件
cat <<EOF | sudo tee /etc/snell/snell-server.conf
[snell-server]
listen = 0.0.0.0:8388
psk = $SNELL_PASSWORD
EOF

# 创建 Systemd 服务文件用于 Snell
cat <<EOF | sudo tee /etc/systemd/system/snell.service
[Unit]
Description=Snell Server Service
After=network.target

[Service]
ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl enable snell
#sudo systemctl start snell

echo "Snell 服务器安装配置完成！"
echo "Snell 密码: $SNELL_PASSWORD"

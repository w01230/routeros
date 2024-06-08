#!/bin/bash

# 创建目录用于存储 TUIC
sudo mkdir -p /etc/tuic
cd /etc/tuic

# 下载并安装 TUIC 最新版本
TUIC_URL="https://github.com/EAimTY/tuic/releases/latest/download/tuic-server-linux-amd64.zip"
wget $TUIC_URL -O tuic.zip
unzip tuic.zip

# 获取解压后的文件夹名称
TUIC_DIR=$(unzip -Z1 tuic.zip | head -1 | cut -d '/' -f1)

# 移动 tuic-server 可执行文件到 /usr/local/bin/
sudo mv $TUIC_DIR/tuic-server /usr/local/bin/
rm -r $TUIC_DIR
rm tuic.zip

# 生成随机密码
TUIC_PASSWORD=$(openssl rand -base64 16)

# 创建 TUIC 配置文件
cat <<EOF | sudo tee /etc/tuic/tuic-config.json
{
    "server": "0.0.0.0:10443",
    "users": {
        "uuid": "psk"
    },
    "certificate": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/n.0.xyz/n.0.xyz.crt",
    "private_key": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/n.0.xyz/n.0.xyz.key",
    "congestion_control": "bbr",
    "alpn": ["h3"],
    "log_level": "warn"
}
EOF

# 创建 Systemd 服务文件用于 TUIC
cat <<EOF | sudo tee /etc/systemd/system/tuic.service
[Unit]
Description=TUIC Server Service
After=network.target

[Service]
ExecStart=/usr/local/bin/tuic-server -c /etc/tuic/tuic-config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl enable tuic
#sudo systemctl start tuic

echo "TUIC 服务器安装配置完成！"
echo "TUIC 密码: $TUIC_PASSWORD"

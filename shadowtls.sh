#!/bin/bash

# 下载并安装 Sing-box 最新版本
LATEST_SINGBOX_URL=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
wget $LATEST_SINGBOX_URL -O sing-box-linux-amd64.tar.gz
tar -xzf sing-box-linux-amd64.tar.gz

# 获取解压后的文件夹名称
SINGBOX_DIR=$(tar -tf sing-box-linux-amd64.tar.gz | head -1 | cut -f1 -d"/")

# 移动 sing-box 可执行文件到 /usr/local/bin/
sudo mv $SINGBOX_DIR/sing-box /usr/local/bin/

# 生成随机密码
SHADOWSOCKS_PASSWORD=$(openssl rand -base64 16)
SHADOWTLS_PASSWORD=$(openssl rand -base64 16)

# 创建 Sing-box 配置文件，配置 ShadowTLS 和 Shadowsocks
sudo mkdir -p /etc/sing-box
cat <<EOF | sudo tee /etc/sing-box/config.json
{
    "log": 
    {
        "level": "warn"
    },

    "inbounds": 
    [
        {
            "type": "shadowtls",
            "listen": "::",
            "listen_port": 443,
            "detour": "shadowsocks-in",
            "version": 3,
            "users": 
            [
                {
                    "password": "$SHADOWTLS_PASSWORD"
                }
            ],
            "handshake": 
            {
                "server": "icloud.com",
                "server_port": 443
            },
            "strict_mode": true
        },
        {
            "type": "shadowsocks",
            "tag": "shadowsocks-in",
            "listen": "127.0.0.1",
            "method": "2022-blake3-aes-128-gcm",
            "password": "$SHADOWSOCKS_PASSWORD", 
            "multiplex": 
            {
                "enabled": true,
                "padding": true
            }
        }
    ],

    "outbounds": 
    [
        {
            "type": "direct"
        }
    ]
}
EOF

# 创建 Systemd 服务文件用于 Sing-box
cat <<EOF | sudo tee /etc/systemd/system/sing-box.service
[Unit]
Description=Sing-box Service
After=network.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl enable sing-box
#sudo systemctl start sing-box

echo "Sing-box 安装配置完成！"
echo "Shadowsocks 密码: $SHADOWSOCKS_PASSWORD"
echo "ShadowTLS 密码: $SHADOWTLS_PASSWORD"

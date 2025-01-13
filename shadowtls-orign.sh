#!/usr/bin/env bash

# 变量设置
SS_PORT=24000
TLS_PORT=443
SS_METHOD="aes-128-gcm"
SS_PASSWORD=$(openssl rand -base64 16)  # 动态生成16字节密码
SHADOWTLS_VERSION="0.5.3"
SSRUST_VERSION="1.18.0"

# 创建工作目录
mkdir -p /usr/local/bin
mkdir -p /etc/shadowsocks
mkdir -p /etc/shadowtls

# 下载 Shadowsocks-rust
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${SSRUST_VERSION}/shadowsocks-v${SSRUST_VERSION}.x86_64-unknown-linux-gnu.tar.xz
tar -xf shadowsocks-v${SSRUST_VERSION}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin
chmod +x /usr/local/bin/ss*

# 下载 ShadowTLS
wget https://github.com/ihciah/shadow-tls/releases/download/v${SHADOWTLS_VERSION}/shadow-tls-x86_64-unknown-linux-gnu.tar.gz
tar -xf shadow-tls-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/shadow-tls

# 创建 Shadowsocks 配置
cat > /etc/shadowsocks/config.json << EOF
{
    "server": "127.0.0.1",
    "server_port": ${SS_PORT},
    "password": "${SS_PASSWORD}",
    "method": "${SS_METHOD}",
    "timeout": 300,
    "fast_open": true
}
EOF

# 创建 ShadowTLS 配置
cat > /etc/shadowtls/config.json << EOF
{
    "server": {
        "listen": "0.0.0.0:${TLS_PORT}",
        "server_addr": "127.0.0.1:${SS_PORT}",
        "tls_addr": {
            "dispatch": {
                "icloud.com": "icloud.com:443"
            },
            "fallback": "cloudflare.com:443"
        }
    }
}
EOF

# 创建 Shadowsocks systemd 服务
cat > /etc/systemd/system/shadowsocks.service << EOF
[Unit]
Description=Shadowsocks-rust Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/config.json
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# 创建 ShadowTLS systemd 服务
cat > /etc/systemd/system/shadowtls.service << EOF
[Unit]
Description=ShadowTLS Server
After=network.target shadowsocks.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/shadow-tls server --config /etc/shadowtls/config.json
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# 设置权限
chmod 600 /etc/shadowsocks/config.json
chmod 600 /etc/shadowtls/config.json

# 启动服务
systemctl daemon-reload
systemctl enable shadowsocks shadowtls
systemctl start shadowsocks shadowtls

# 清理安装文件
rm -f shadowsocks-v${SSRUST_VERSION}.x86_64-unknown-linux-gnu.tar.xz
rm -f shadow-tls-x86_64-unknown-linux-gnu.tar.gz

# 输出配置信息
echo "安装完成！"
echo "Shadowsocks 配置："
echo "端口: ${TLS_PORT}"
echo "加密方式: ${SS_METHOD}"
echo "密码: ${SS_PASSWORD}"
echo
echo "服务状态："
systemctl status shadowsocks --no-pager
systemctl status shadowtls --no-pager
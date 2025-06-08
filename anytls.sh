#!/bin/bash

# 检查root权限
if [ "$(id -u)" != "0" ]; then
    echo "错误：此脚本必须以root权限运行！"
    exit 1
fi

# 设置临时工作目录为当前目录
TEMP_DIR=$(pwd)
cd "$TEMP_DIR" || exit

# 设置用户名和密码（可修改）
USERNAME="000"
PASSWORD="000"

# 设置证书路径（可自定义）
DOMAIN_NAME="n.nnn.xyz"
CERT_DIR="/etc/mihomo/cert"  # 证书存储目录
CERT_FILE="$CERT_DIR/$DOMAIN_NAME.crt"  # 证书文件路径
KEY_FILE="$CERT_DIR/$DOMAIN_NAME.key"   # 私钥文件路径

# 获取最新版Mihomo的下载链接（精确匹配linux-amd64的.gz文件）
echo "获取最新版Mihomo..."
LATEST_RELEASE=$(curl -sL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
| grep "browser_download_url.*linux-amd64.*\.gz\"" \
| grep -v "compatible\|go\|deb\|rpm\|pkg" \
| cut -d '"' -f 4 | head -n 1)

# 如果找不到精确匹配，尝试任何linux-amd64的.gz文件
if [ -z "$LATEST_RELEASE" ]; then
    LATEST_RELEASE=$(curl -sL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
    | grep "browser_download_url.*linux-amd64.*\.gz\"" \
    | cut -d '"' -f 4 | head -n 1)
fi

if [ -z "$LATEST_RELEASE" ]; then
    echo "错误：无法获取下载链接！"
    exit 1
fi

echo "下载链接: $LATEST_RELEASE"

# 下载Mihomo
echo "正在下载Mihomo..."
wget -q --show-progress -O mihomo.gz "$LATEST_RELEASE"
if [ ! -f mihomo.gz ]; then
    echo "错误：下载失败！"
    exit 1
fi

# 解压文件
gunzip mihomo.gz
mv mihomo mihomo-bin
chmod +x mihomo-bin

# 安装二进制文件
echo "正在安装二进制文件到/usr/local/bin..."
mv mihomo-bin /usr/local/bin/mihomo

# SELINUX Contex
semanage fcontext -a -t bin_t "/usr/local/bin/mihomo"
restorecon -v /usr/local/bin/mihomo

# 创建配置目录
echo "创建配置目录/etc/mihomo..."
mkdir -p /etc/mihomo
ln -s /root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/$DOMAIN_NAME/ /etc/mihomo/cert

# 生成配置文件
echo "生成配置文件..."
cat > /etc/mihomo/config.yaml <<EOF
listeners:
- name: anytls-server
  type: anytls
  port: 8443
  listen: ::0
  users:
    $USERNAME: $PASSWORD
  certificate: $CERT_FILE
  private-key: $KEY_FILE
  padding-scheme: |
   stop=8
   0=30-30
   1=100-400
   2=400-500,c,500-1000,c,500-1000,c,500-1000,c,500-1000
   3=9-9,500-1000
   4=500-1000
   5=500-1000
   6=500-1000
   7=500-1000
EOF

# 创建systemd服务文件
echo "创建systemd服务..."
cat > /etc/systemd/system/mihomo.service <<EOF
[Unit]
Description=Mihomo Proxy Service
After=network.target

[Service]
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd并启动服务
echo "启动服务..."
systemctl daemon-reload
systemctl enable --now mihomo.service

# 检查服务状态
sleep 3  # 等待服务启动
if systemctl is-active --quiet mihomo.service; then
    echo "服务启动成功！"
    echo "代理配置信息："
    echo "服务器: $(curl -s ifconfig.me)"
    echo "端口: 8443"
    echo "用户名: $USERNAME"
    echo "密码: $PASSWORD"
    echo "证书路径: $CERT_FILE"
else
    echo "错误：服务启动失败！"
    journalctl -u mihomo.service -n 10 --no-pager
    exit 1
fi

echo "安装完成！"

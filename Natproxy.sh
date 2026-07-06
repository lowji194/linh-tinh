#!/bin/bash
#
# Script cài đặt 3proxy trên Ubuntu 24 - Tạo Proxy IPv4 (HTTP + SOCKS5)
# Chạy với quyền root: sudo bash setup_proxy.sh
#
set -e
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền root (sudo bash setup_proxy.sh)"
  exit 1
fi
# ===== CẤU HÌNH =====
# Cách dùng: sudo bash setup_proxy.sh <user> <pass> <http_port>
# Ví dụ:     sudo bash setup_proxy.sh myuser MyPass123 3128
# SOCKS5 port sẽ TỰ ĐỘNG = http_port + 1000 (vd: 3128 -> 4128)
#
# Nếu không truyền tham số, sẽ dùng giá trị mặc định bên dưới.
PROXY_USER="${1:-proxyuser}"
PROXY_PASS="${2:-MatKhauManh123!}"
HTTP_PORT="${3:-3128}"
SOCKS_PORT=$((HTTP_PORT + 1000))
# ======================================================
echo ">>> Cập nhật hệ thống..."
apt update -y
echo ">>> Cài đặt các gói cần thiết..."
apt install -y build-essential git wget curl ufw
echo ">>> Tải và biên dịch 3proxy..."
cd /opt
if [ -d "3proxy" ]; then
  rm -rf 3proxy
fi
git clone https://github.com/3proxy/3proxy.git
cd 3proxy
ln -sf Makefile.Linux Makefile
make -f Makefile
echo ">>> Cài đặt 3proxy vào hệ thống..."
mkdir -p /usr/local/3proxy/{bin,logs,conf}
cp bin/3proxy /usr/local/3proxy/bin/
chmod +x /usr/local/3proxy/bin/3proxy
# Lấy IP public của VPS
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com)
echo ">>> IP VPS phát hiện được: $SERVER_IP"
echo ">>> Tạo file cấu hình 3proxy..."
cat > /usr/local/3proxy/conf/3proxy.cfg <<EOF
daemon
maxconn 200
nserver 8.8.8.8
nserver 1.1.1.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log /usr/local/3proxy/logs/3proxy.log D
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"
rotate 7
auth strong
users ${PROXY_USER}:CL:${PROXY_PASS}
allow ${PROXY_USER}
# HTTP Proxy
proxy -p${HTTP_PORT} -a -i0.0.0.0 -e${SERVER_IP}
# SOCKS5 Proxy
socks -p${SOCKS_PORT} -a -i0.0.0.0 -e${SERVER_IP}
flush
EOF
echo ">>> Tạo systemd service cho 3proxy..."
cat > /etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3proxy Proxy Server
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/3proxy/bin/3proxy /usr/local/3proxy/conf/3proxy.cfg
ExecStop=/bin/kill -TERM \$MAINPID
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
echo ">>> Bật NAT/IP forwarding (nếu VPS có nhiều IP)..."
sysctl -w net.ipv4.ip_forward=1
if ! grep -q "net.ipv4.ip_forward" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
echo ">>> Mở firewall cho cổng proxy..."
ufw allow ${HTTP_PORT}/tcp
ufw allow ${SOCKS_PORT}/tcp
ufw allow OpenSSH
ufw --force enable
echo ">>> Kích hoạt và khởi động dịch vụ..."
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy
sleep 2
systemctl status 3proxy --no-pager
echo ""
echo "========================================================"
echo "  CÀI ĐẶT HOÀN TẤT!"
echo "========================================================"
echo "  HTTP Proxy : ${SERVER_IP}:${HTTP_PORT}"
echo "  SOCKS5     : ${SERVER_IP}:${SOCKS_PORT}"
echo "  Username   : ${PROXY_USER}"
echo "  Password   : ${PROXY_PASS}"
echo ""
echo "  Test HTTP proxy:"
echo "  curl -x http://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${HTTP_PORT} https://ifconfig.me"
echo ""
echo "  Test SOCKS5 proxy:"
echo "  curl --socks5 ${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${SOCKS_PORT} https://ifconfig.me"
echo "========================================================"

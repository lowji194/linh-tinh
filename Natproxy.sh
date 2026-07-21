#!/bin/bash
#
# Script cài đặt 3proxy trên Ubuntu 24 - Tạo Proxy IPv4 (HTTP + SOCKS5)
# Dùng source riêng (LowjiProxy.tar.gz) - KHÔNG git clone
# Kèm health-check tự động (mỗi 5 phút) restart nếu proxy die
#
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
PROXY_USER="${1:-proxyuser}"
PROXY_PASS="${2:-MatKhauManh123!}"
HTTP_PORT="${3:-3128}"
SOCKS_PORT=$((HTTP_PORT + 1000))

# Nguồn source riêng
SRC_URL="https://github.com/lowji194/documentation/raw/main/LowjiProxy.tar.gz"
SRC_DIR="/opt/LowjiProxy"
BIN_PATH="/usr/local/3proxy/bin/3proxy"
CFG_PATH="/usr/local/3proxy/conf/3proxy.cfg"
CHECK_SCRIPT="/usr/local/3proxy/bin/healthcheck.sh"

# ======================================================
echo ">>> Cập nhật hệ thống..."
apt update -y

echo ">>> Cài đặt các gói cần thiết..."
apt install -y build-essential libarchive-tools wget curl ufw

echo ">>> Tải và giải nén source 3proxy (LowjiProxy)..."
cd /opt
rm -rf "$SRC_DIR"
wget -qO- "$SRC_URL" | bsdtar -xvf-

if [ ! -d "$SRC_DIR" ]; then
  echo "Lỗi: Không tìm thấy thư mục $SRC_DIR sau khi giải nén. Kiểm tra lại tên thư mục trong file nén."
  exit 1
fi

echo ">>> Biên dịch source..."
cd "$SRC_DIR"
make -f Makefile.Linux

echo ">>> Cài đặt 3proxy vào hệ thống..."
mkdir -p /usr/local/3proxy/{bin,logs,conf}
cp bin/3proxy "$BIN_PATH"
chmod +x "$BIN_PATH"

# Lấy IP public của VPS
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com)
echo ">>> IP VPS phát hiện được: $SERVER_IP"

echo ">>> Tạo file cấu hình 3proxy..."
cat > "$CFG_PATH" <<EOF
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
ExecStart=${BIN_PATH} ${CFG_PATH}
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

echo ">>> Kích hoạt và khởi động dịch vụ 3proxy..."
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy
sleep 2
systemctl status 3proxy --no-pager || true

# ======================================================
# HEALTH CHECK - kiểm tra proxy còn sống mỗi 5 phút, tự restart nếu die
# ======================================================
echo ">>> Tạo script health-check..."
cat > "$CHECK_SCRIPT" <<'EOF'
#!/bin/bash
# Kiểm tra service 3proxy có đang chạy không, nếu không thì restart
if ! systemctl is-active --quiet 3proxy; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 3proxy DIE, đang restart..." >> /usr/local/3proxy/logs/healthcheck.log
    systemctl restart 3proxy
else
    # Kiểm tra thêm cổng có đang listen không (phòng trường hợp process sống nhưng treo)
    if ! ss -ltn | grep -q ":${1} "; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Port ${1} không listen dù service active, đang restart..." >> /usr/local/3proxy/logs/healthcheck.log
        systemctl restart 3proxy
    fi
fi
EOF
chmod +x "$CHECK_SCRIPT"

echo ">>> Tạo systemd service + timer chạy health-check mỗi 5 phút..."
cat > /etc/systemd/system/3proxy-healthcheck.service <<EOF
[Unit]
Description=3proxy Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=${CHECK_SCRIPT} ${HTTP_PORT}
EOF

cat > /etc/systemd/system/3proxy-healthcheck.timer <<'EOF'
[Unit]
Description=Run 3proxy Health Check every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=3proxy-healthcheck.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now 3proxy-healthcheck.timer

echo ""
echo "========================================================"
echo "  CÀI ĐẶT HOÀN TẤT!"
echo "========================================================"
echo "  HTTP Proxy : ${SERVER_IP}:${HTTP_PORT}"
echo "  SOCKS5     : ${SERVER_IP}:${SOCKS_PORT}"
echo "  Username   : ${PROXY_USER}"
echo "  Password   : ${PROXY_PASS}"
echo ""
echo "  Health-check: chạy mỗi 5 phút qua systemd timer 3proxy-healthcheck.timer"
echo "  Xem log:      tail -f /usr/local/3proxy/logs/healthcheck.log"
echo "  Xem timer:    systemctl list-timers | grep 3proxy"
echo ""
echo "  Test HTTP proxy:"
echo "  curl -x http://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${HTTP_PORT} https://ifconfig.me"
echo ""
echo "  Test SOCKS5 proxy:"
echo "  curl --socks5 ${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${SOCKS_PORT} https://ifconfig.me"
echo "========================================================"

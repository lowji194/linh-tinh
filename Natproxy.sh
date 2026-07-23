#!/bin/bash
#
# Script cài đặt 3proxy trên Ubuntu 24 - Tạo Proxy IPv4 (HTTP + SOCKS5)
# Dùng source riêng (LowjiProxy.tar.gz) - KHÔNG git clone
# Kèm:
#   - health-check tự động (mỗi 5 phút) restart nếu proxy die
#   - auth theo IP whitelist (iponly) kết hợp auth user/pass (strong)
#   - tự động theo dõi IP của 1 domain (DDNS) mỗi 5 phút, cập nhật
#     whitelist + restart proxy nếu IP đổi
#
# Chạy với quyền root: sudo bash setup_proxy.sh
#
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền root (sudo bash setup_proxy.sh)"
  exit 1
fi

# ===== CẤU HÌNH =====
# Cách dùng: sudo bash setup_proxy.sh <user> <pass> <http_port> [ddns_domain]
# Ví dụ:     sudo bash setup_proxy.sh myuser MyPass123 3128 theloi.io.vn
# SOCKS5 port sẽ TỰ ĐỘNG = http_port + 1000 (vd: 3128 -> 4128)
# Nếu không truyền ddns_domain, mặc định dùng theloi.io.vn
#
PROXY_USER="${1:-proxyuser}"
PROXY_PASS="${2:-MatKhauManh123!}"
HTTP_PORT="${3:-3128}"
SOCKS_PORT=$((HTTP_PORT + 1000))
DDNS_DOMAIN="${4:-key.theloi.io.vn}"

# Nguồn source riêng
SRC_URL="https://github.com/lowji194/documentation/raw/main/LowjiProxy.tar.gz"
SRC_DIR="/opt/LowjiProxy"
BIN_PATH="/usr/local/3proxy/bin/3proxy"
CFG_PATH="/usr/local/3proxy/conf/3proxy.cfg"
ALLOW_IPS_FILE="/usr/local/3proxy/conf/allow_ips.list"
CHECK_SCRIPT="/usr/local/3proxy/bin/healthcheck.sh"
DDNS_CHECK_SCRIPT="/usr/local/3proxy/bin/ddns_check.sh"

# ======================================================
echo ">>> Cập nhật hệ thống..."
apt update -y

echo ">>> Cài đặt các gói cần thiết..."
apt install -y build-essential libarchive-tools wget curl ufw dnsutils

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

# ======================================================
# DỪNG SERVICE CŨ TRƯỚC KHI GHI ĐÈ BINARY
# (tránh lỗi "Text file busy" khi 3proxy cũ đang chạy và giữ file binary)
# ======================================================
echo ">>> Dừng 3proxy cũ (nếu đang chạy) trước khi ghi đè binary..."
systemctl stop 3proxy-healthcheck.timer 2>/dev/null || true
systemctl stop 3proxy-ddnscheck.timer 2>/dev/null || true
systemctl stop 3proxy 2>/dev/null || true
pkill -x 3proxy 2>/dev/null || true
sleep 1

echo ">>> Cài đặt 3proxy vào hệ thống..."
mkdir -p /usr/local/3proxy/{bin,logs,conf}
rm -f "$BIN_PATH"          # xoá inode cũ để cp không bị "Text file busy"
cp bin/3proxy "$BIN_PATH"
chmod +x "$BIN_PATH"

# Lấy IP public của VPS
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com)
echo ">>> IP VPS phát hiện được: $SERVER_IP"

# ======================================================
# WHITELIST IP - khởi tạo file allow_ips.list
# Resolve IP hiện tại của domain DDNS (nếu resolve được) để đưa
# vào whitelist ngay từ đầu, tránh phải đợi lần chạy timer đầu tiên
# ======================================================
echo ">>> Khởi tạo whitelist IP (auth iponly) cho domain: ${DDNS_DOMAIN}..."
INIT_IP=$(dig +short "$DDNS_DOMAIN" | tail -n1)
if [ -z "$INIT_IP" ]; then
  INIT_IP=$(getent hosts "$DDNS_DOMAIN" | awk '{print $1}' | head -n1)
fi

if [ -n "$INIT_IP" ]; then
  echo "allow * ${INIT_IP}" > "$ALLOW_IPS_FILE"
  echo "    -> Đã thêm ${INIT_IP} (IP hiện tại của ${DDNS_DOMAIN}) vào whitelist."
else
  # Chưa resolve được thì tạo file rỗng (hợp lệ với 3proxy), sẽ được
  # điền bởi ddns_check.sh ở lần chạy đầu của timer
  : > "$ALLOW_IPS_FILE"
  echo "    -> Không resolve được ${DDNS_DOMAIN} lúc cài đặt, sẽ tự điền khi timer chạy."
fi

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
# auth iponly: IP nằm trong allow_ips.list được đi thẳng, không cần user/pass
# auth strong: các kết nối còn lại bắt buộc user/pass
auth iponly strong
include ${ALLOW_IPS_FILE}
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

# ======================================================
# DDNS CHECK - theo dõi IP của domain mỗi 5 phút, cập nhật whitelist
# và restart proxy nếu IP thay đổi
# ======================================================
echo ">>> Tạo script theo dõi IP domain (${DDNS_DOMAIN})..."
cat > "$DDNS_CHECK_SCRIPT" <<EOF
#!/bin/bash
# Theo dõi IP hiện tại của domain, nếu đổi thì cập nhật allow_ips.list
# và restart 3proxy để áp dụng whitelist mới
DOMAIN="${DDNS_DOMAIN}"
ALLOW_FILE="${ALLOW_IPS_FILE}"
LOG="/usr/local/3proxy/logs/ddns_check.log"

NEW_IP=\$(dig +short "\$DOMAIN" | tail -n1)
if [ -z "\$NEW_IP" ]; then
    NEW_IP=\$(getent hosts "\$DOMAIN" | awk '{print \$1}' | head -n1)
fi

if [ -z "\$NEW_IP" ]; then
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - Không resolve được IP của \$DOMAIN, bỏ qua." >> "\$LOG"
    exit 0
fi

CURRENT_IP=""
if [ -f "\$ALLOW_FILE" ]; then
    CURRENT_IP=\$(grep -m1 '^allow \* ' "\$ALLOW_FILE" | awk '{print \$3}')
fi

if [ "\$NEW_IP" != "\$CURRENT_IP" ]; then
    echo "allow * \${NEW_IP}" > "\$ALLOW_FILE"
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - IP của \$DOMAIN đổi: \${CURRENT_IP:-<trống>} -> \${NEW_IP}. Đã cập nhật whitelist + restart 3proxy." >> "\$LOG"
    systemctl restart 3proxy
else
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - IP của \$DOMAIN không đổi (\${NEW_IP})." >> "\$LOG"
fi
EOF
chmod +x "$DDNS_CHECK_SCRIPT"

echo ">>> Tạo systemd service + timer theo dõi IP domain mỗi 5 phút..."
cat > /etc/systemd/system/3proxy-ddnscheck.service <<EOF
[Unit]
Description=3proxy DDNS IP Whitelist Check (${DDNS_DOMAIN})
After=network.target

[Service]
Type=oneshot
ExecStart=${DDNS_CHECK_SCRIPT}
EOF

cat > /etc/systemd/system/3proxy-ddnscheck.timer <<'EOF'
[Unit]
Description=Run 3proxy DDNS IP check every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=3proxy-ddnscheck.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now 3proxy-healthcheck.timer
systemctl enable --now 3proxy-ddnscheck.timer

echo ""
echo "========================================================"
echo "  CÀI ĐẶT HOÀN TẤT!"
echo "========================================================"
echo "  HTTP Proxy : ${SERVER_IP}:${HTTP_PORT}"
echo "  SOCKS5     : ${SERVER_IP}:${SOCKS_PORT}"
echo "  Username   : ${PROXY_USER}"
echo "  Password   : ${PROXY_PASS}"
echo ""
echo "  Auth theo IP whitelist:"
echo "    File whitelist: ${ALLOW_IPS_FILE}"
echo "    Domain theo dõi: ${DDNS_DOMAIN} (tự cập nhật mỗi 5 phút)"
echo "    Xem log DDNS:    tail -f /usr/local/3proxy/logs/ddns_check.log"
echo "    Xem timer:       systemctl list-timers | grep 3proxy"
echo ""
echo "  Health-check: chạy mỗi 5 phút qua systemd timer 3proxy-healthcheck.timer"
echo "  Xem log:      tail -f /usr/local/3proxy/logs/healthcheck.log"
echo ""
echo "  Test HTTP proxy (bằng user/pass):"
echo "  curl -x http://${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${HTTP_PORT} https://ifconfig.me"
echo ""
echo "  Test SOCKS5 proxy (bằng user/pass):"
echo "  curl --socks5 ${PROXY_USER}:${PROXY_PASS}@${SERVER_IP}:${SOCKS_PORT} https://ifconfig.me"
echo ""
echo "  Nếu IP máy bạn nằm trong whitelist (trùng IP domain ${DDNS_DOMAIN}),"
echo "  có thể dùng proxy KHÔNG CẦN user/pass:"
echo "  curl -x http://${SERVER_IP}:${HTTP_PORT} https://ifconfig.me"
echo "========================================================"

#!/bin/bash
#
# ============================================================
#  install-motd.sh  (bản gộp 1 file)
#  Cài đặt Custom MOTD (Hacker/Developer style) cho Ubuntu
#
#  Cách dùng:
#    chmod +x install-motd.sh
#    sudo ./install-motd.sh
# ============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌  Vui lòng chạy với quyền root: sudo ./install-motd.sh"
    exit 1
fi

TARGET_FILE="/etc/update-motd.d/99-custom"

echo "==> Sao lưu các script MOTD mặc định (nếu chưa có bản sao lưu)..."
if [ -d /etc/update-motd.d ] && [ ! -d /etc/update-motd.d.bak ]; then
    cp -r /etc/update-motd.d /etc/update-motd.d.bak
    echo "    Đã sao lưu vào /etc/update-motd.d.bak"
fi

echo "==> Vô hiệu hóa các script MOTD mặc định của Ubuntu..."
if [ -d /etc/update-motd.d ]; then
    for f in /etc/update-motd.d/*; do
        [ -f "$f" ] && chmod -x "$f" 2>/dev/null || true
    done
fi

echo "==> Ghi script MOTD tùy chỉnh vào $TARGET_FILE ..."
cat > "$TARGET_FILE" << 'MOTD_EOF'
#!/bin/bash
#
# ============================================================
#  Custom MOTD — Hacker / Developer Style
#  Ubuntu 22.04 LTS
# ============================================================

# ---------- MÀU SẮC ----------
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

GREEN="\e[38;5;46m"
DGREEN="\e[38;5;28m"
CYAN="\e[38;5;51m"
MAGENTA="\e[38;5;201m"
YELLOW="\e[38;5;226m"
RED="\e[38;5;196m"
GRAY="\e[38;5;240m"
WHITE="\e[38;5;231m"

# ---------- THU THẬP THÔNG TIN HỆ THỐNG ----------
HOSTNAME=$(hostname)
OS_NAME=$(grep -oP '(?<=PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null)
KERNEL=$(uname -r)
ARCH=$(uname -m)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
LOAD=$(cut -d ' ' -f1-3 /proc/loadavg)
USERS=$(who | wc -l)

# CPU
CPU_MODEL=$(lscpu 2>/dev/null | grep 'Model name' | sed 's/Model name:\s*//' | head -1)
CPU_CORES=$(nproc)
CPU_USAGE=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2 + $4}')

# RAM (chỉ lấy tổng)
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')

# DISK
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# NETWORK
IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}')
IP_PUBLIC=$(timeout 2 curl -4 -s https://api.ipify.org 2>/dev/null)
if ! [[ "$IP_PUBLIC" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    IP_PUBLIC=$(timeout 2 curl -4 -s https://ifconfig.me 2>/dev/null)
fi
if ! [[ "$IP_PUBLIC" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    IP_PUBLIC="N/A"
fi

# SSH
LAST_LOGIN=$(last -i -n 2 "$USER" 2>/dev/null | sed -n 2p | awk '{print $3, $4, $5, $6, $7}')

# PACKAGES CẦN CẬP NHẬT
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

clear
echo -e "${DGREEN}"
cat << "EOF"
####################################################################
#        _           _   _   _                                     #
#       | |         (_) | \ | |                                    #
#       | |     ___  _  |  \| | __ _ _   _ _   _  ___ _ __         #
#       | |    / _ \| | | . ` |/ _` | | | | | | |/ _ \ '_ \        #
#       | |___| (_) | | | |\  | (_| | |_| | |_| |  __/ | | |       #
#       |______\___/|_| |_| \_|\__, |\__,_|\__, |\___|_| |_|       #
#                               __/ |       __/ |                  #
#                              |___/       |___/                   #
####################################################################
EOF
echo -e "${RESET}"

SEP="    ${GRAY}├────────────────────────${RESET}"
echo -e "    ${GRAY}┌────────────────────────${RESET}"
printf  "    ${GRAY}│${RESET} ${CYAN}%-14s${RESET} ${WHITE}%s${RESET}\n" "System" "$OS_NAME"
printf  "    ${GRAY}│${RESET} ${CYAN}%-14s${RESET} ${WHITE}%s${RESET}\n" "Kernel" "$KERNEL ($ARCH)"
printf  "    ${GRAY}│${RESET} ${CYAN}%-14s${RESET} ${WHITE}%s${RESET}\n" "Hostname" "$HOSTNAME"
printf  "    ${GRAY}│${RESET} ${CYAN}%-14s${RESET} ${WHITE}%s${RESET}\n" "Uptime" "$UPTIME"
printf  "    ${GRAY}│${RESET} ${CYAN}%-14s${RESET} ${WHITE}%s${RESET}\n" "Load avg" "$LOAD"
echo -e "$SEP"
printf  "    ${GRAY}│${RESET} ${MAGENTA}%-14s${RESET} ${WHITE}%s${RESET}\n" "CPU" "$CPU_MODEL"
printf  "    ${GRAY}│${RESET} ${MAGENTA}%-14s${RESET} ${WHITE}%s cores${RESET}\n" "Cores" "$CPU_CORES"
printf  "    ${GRAY}│${RESET} ${MAGENTA}%-14s${RESET} ${WHITE}%sMB${RESET}\n" "RAM" "$RAM_TOTAL"
printf  "    ${GRAY}│${RESET} ${MAGENTA}%-14s${RESET} ${WHITE}%s${RESET}\n" "Disk (/)" "$DISK_INFO"
echo -e "$SEP"
printf  "    ${GRAY}│${RESET} ${YELLOW}%-14s${RESET} ${WHITE}%s${RESET}\n" "Local IP" "$IP_LOCAL"
printf  "    ${GRAY}│${RESET} ${YELLOW}%-14s${RESET} ${WHITE}%s${RESET}\n" "Public IP" "$IP_PUBLIC"
printf  "    ${GRAY}│${RESET} ${YELLOW}%-14s${RESET} ${WHITE}%s${RESET}\n" "Users online" "$USERS"
if [ "$UPDATES" -gt 0 ]; then
    printf "    ${GRAY}│${RESET} ${RED}%-14s${RESET} ${WHITE}%s gói cần cập nhật${RESET}\n" "Updates" "$UPDATES"
else
    printf "    ${GRAY}│${RESET} ${GREEN}%-14s${RESET} ${WHITE}Hệ thống đã cập nhật${RESET}\n" "Updates"
fi
echo -e "    ${GRAY}└────────────────────────${RESET}"

echo -e "${DIM}${GREEN}    \$ ${RESET}${DIM}whoami${RESET} ${DGREEN}=> ${WHITE}${USER}@${HOSTNAME}${RESET}"
echo -e "${DIM}${GRAY}    Đăng nhập lần trước: ${LAST_LOGIN:-không rõ}${RESET}"
echo ""
MOTD_EOF

chmod +x "$TARGET_FILE"
chown root:root "$TARGET_FILE"

echo "==> Vô hiệu hóa /etc/motd tĩnh (nếu có)..."
if [ -f /etc/motd ]; then
    mv /etc/motd /etc/motd.bak 2>/dev/null || true
fi
touch /etc/motd

echo "==> Đảm bảo PAM bật hiển thị MOTD động khi SSH..."
if [ -f /etc/pam.d/sshd ]; then
    if ! grep -q "pam_motd.so.*update-motd" /etc/pam.d/sshd; then
        sed -i '/pam_motd.so/d' /etc/pam.d/sshd
        sed -i '1i session    optional     pam_motd.so  motd=/run/motd.dynamic' /etc/pam.d/sshd
        sed -i '2i session    optional     pam_motd.so noupdate' /etc/pam.d/sshd
    fi
fi

echo ""
echo "✅  Cài đặt hoàn tất!"
echo "    - Script MOTD: $TARGET_FILE"
echo "    - Sao lưu MOTD gốc: /etc/update-motd.d.bak (nếu có)"
echo "    - Đăng nhập SSH lại (hoặc chạy: sudo run-parts /etc/update-motd.d) để xem kết quả."
echo ""

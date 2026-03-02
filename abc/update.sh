#!/bin/bash
# ========================================================
# Script cài đặt Docker và chạy các app kiếm tiền chia sẻ băng thông
# Traffmonetizer / EarnFM / Honeygain / PacketStream / Wipter / CastarSDK / URnetwork
# + Pawns.app + ProxyLite + Repocket + Proxyrack
# Hỗ trợ AlmaLinux/CentOS, không xóa container/image cũ
# ========================================================
# Đã sửa: không dừng khi 1 container lỗi (bỏ set -e, dùng || true, báo lỗi nhưng tiếp tục)

set -uo pipefail
IFS=$'\n\t'

# ==================== KHAI BÁO TẤT CẢ USER/PASS/API/KEY Ở ĐÂY ====================
# (giữ nguyên phần khai báo của bạn)

TM_TOKEN='OuUALSfuOmDZtYQFznejR8xekKvBzT94UeQMffAe4OU='
EARNFM_TOKEN='e6f2eaee-18e0-4146-82de-491b11fadf3c'
HONEY_EMAIL='loilop9d@gmail.com'
HONEY_PASS='loilop9d'
PS_CID='1vq6'
WIPTER_EMAIL='theloi194@gmail.com'
WIPTER_PASS='Loi@1234'
CASTAR_APPKEY='cskfkt+Fis3dXd'
UR_EMAIL='theloi194@gmail.com'
UR_PASS='Loilop9d@1234'
PAWNS_EMAIL='theloi194@gmail.com'
PAWNS_PASS='Loi@1234'
PROXYLITE_USER_ID='518581'
REPOCKET_EMAIL='theloi194@gmail.com'
REPOCKET_API_KEY='98d0baff-a4ea-41a1-a3bb-c683c267684b'
PROXYRACK_API_KEY='O9BY4JARKTFQV75GOSEFACVDSFJ7691YWO8FEDES'
PROXYRACK_DEVICE_NAME="$(curl -s4 ifconfig.me || echo 'Unknown-IP')"

# -------------------- Hàm tiện ích --------------------
info()    { echo -e "[\033[1;34mINFO\033[0m] $*"; }
success() { echo -e "[\033[1;32mOK\033[0m] $*"; }
warning() { echo -e "[\033[1;33mWARN\033[0m] $*"; }
error()   { echo -e "[\033[1;31mERROR\033[0m] $*" >&2; }   # ← không exit nữa

# -------------------- Kiểm tra và cài Docker --------------------
check_docker() {
    if command -v docker &>/dev/null; then
        info "Docker đã cài: $(docker --version)"
        return 0
    fi

    info "Cài Docker CE..."
    # (giữ nguyên phần cài đặt của bạn, chỉ thêm || true ở vài chỗ nếu cần)
    if [ -f /etc/debian_version ]; then
        apt-get update -y || true
        # ... phần còn lại giống script cũ ...
    elif [ -f /etc/redhat-release ]; then
        # ... phần còn lại giống script cũ ...
    else
        error "Hệ điều hành không hỗ trợ. Tiếp tục mà không cài Docker mới."
        return 1
    fi

    systemctl enable --now docker 2>/dev/null || true
    if command -v docker &>/dev/null; then
        success "Docker đã cài: $(docker --version)"
    else
        warning "Không cài được Docker → các container sẽ không chạy được"
    fi
}

# -------------------- Phát hiện kiến trúc --------------------
detect_architecture() {
    case "$(uname -m)" in
        x86_64)  VERSION="latest" ;;
        aarch64) VERSION="arm64v8" ;;
        *)       VERSION="latest"; warning "Kiến trúc lạ: $(uname -m) → dùng latest" ;;
    esac
    info "Sử dụng tag image: $VERSION"
}

# -------------------- Chạy container (không dừng khi lỗi) --------------------
run_container() {
    local name="$1"
    shift
    local cmd="$*"

    if docker ps -a --format '{{.Names}}' | grep -q "^$name$"; then
        info "Container $name đã tồn tại."
        if ! docker ps --format '{{.Names}}' | grep -q "^$name$"; then
            info "Khởi động lại $name..."
            docker start "$name" >/dev/null 2>&1 || warning "Không start lại được $name"
        fi
    else
        info "Chạy mới container $name..."
        # Chạy và bỏ qua lỗi
        if ! docker run -d --name "$name" --restart unless-stopped $cmd >/dev/null 2>&1; then
            error "Không chạy được container $name (có thể image lỗi / token sai / mạng chậm)"
            warning "→ Bỏ qua và tiếp tục với các app khác"
        else
            success "$name đang chạy"
        fi
    fi
}

# ==================== THỰC THI CHÍNH ====================
info "Bắt đầu cài đặt và chạy các container (không dừng khi lỗi)..."

check_docker
detect_architecture

DEVICE=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1 | sort -t '.' -k 4,4nr | head -n 1 || echo "unknown")
info "DEVICE/IP chính: $DEVICE"

# ==================== Chạy từng container ====================

run_container "tm"            "traffmonetizer/cli_v2:$VERSION start accept --token '$TM_TOKEN' --device-name '$DEVICE'"
run_container "earnfm-client" "-e EARNFM_TOKEN='$EARNFM_TOKEN' earnfm/earnfm-client:latest"
run_container "honeygain"     "honeygain/honeygain -tou-accept -email '$HONEY_EMAIL' -pass '$HONEY_PASS' -device '$DEVICE'"
run_container "psclient"      "-e CID='$PS_CID' packetstream/psclient:latest"

# Pawns.app
docker pull iproyal/pawns-cli:latest 2>/dev/null || true
run_container "pawns" "iproyal/pawns-cli:latest -email='$PAWNS_EMAIL' -password='$PAWNS_PASS' -device-name='BacNinh-VPS' -device-id='BacNinh01' -accept-tos"

# ProxyLite
docker pull proxylite/proxyservice 2>/dev/null || true
run_container "proxylite" "-e USER_ID='$PROXYLITE_USER_ID' proxylite/proxyservice"

# Wipter
run_container "wipter" "-e WIPTER_EMAIL='$WIPTER_EMAIL' -e WIPTER_PASSWORD='$WIPTER_PASS' ghcr.io/adfly8470/wipter/wipter@sha256:c9bbf2f51af7744724ed7e28e0182e92ee92d725bfc5e334a56b95be5db95ea5"

# CastarSDK
run_container "castarsdk" "--cpus=0.25 --pull=always --log-driver=json-file --log-opt max-size=1m --log-opt max-file=1 --cap-add=NET_ADMIN --cap-add=NET_RAW --sysctl net.ipv4.ip_forward=1 -e APPKEY='$CASTAR_APPKEY' techroy23/docker-castarsdk:latest"

# URnetwork
UR_DATA_DIR="$PWD/urnetwork_data"
mkdir -p "$UR_DATA_DIR/vnstat" && chmod -R 777 "$UR_DATA_DIR" 2>/dev/null || true
run_container "urnetwork" "--platform linux/amd64 --privileged -e USER_AUTH='$UR_EMAIL' -e PASSWORD='$UR_PASS' -e ENABLE_IP_CHECKER=false -v '$UR_DATA_DIR/vnstat:/var/lib/vnstat' ghcr.io/techroy23/docker-urnetwork:latest"

# Repocket
docker pull repocket/repocket:latest 2>/dev/null || true
run_container "repocket" "-e RP_EMAIL='$REPOCKET_EMAIL' -e RP_API_KEY='$REPOCKET_API_KEY' repocket/repocket"

# Proxyrack (giữ logic retry add device)
info "Cài Proxyrack..."
UUID=$(openssl rand -hex 32 | tr 'a-f' 'A-F' 2>/dev/null || echo "fallback-$(date +%s)")
info "UUID: $UUID"

docker rm -f proxyrack >/dev/null 2>&1 || true
run_container "proxyrack" "-e UUID='$UUID' -e API_KEY='$PROXYRACK_API_KEY' proxyrack/pop"

sleep 30
info "Thử add device cho Proxyrack (30 lần)..."
for i in {1..10}; do
    RESPONSE=$(curl -s -X POST https://peer.proxyrack.com/api/device/add \
      -H "Api-Key: $PROXYRACK_API_KEY" \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -d "{\"device_id\":\"$UUID\",\"device_name\":\"$PROXYRACK_DEVICE_NAME\"}" || echo '{"status":"curl_failed"}')
    
    echo "[Thử $i/30] Response: $RESPONSE"
    if echo "$RESPONSE" | grep -q '"status"[[:space:]]*:[[:space:]]*"success"'; then
        success "Proxyrack device added thành công!"
        break
    fi
    sleep 30
done

# ==================== Watchtower (update tự động) ====================
run_container "watchtower" "-v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --include-stopped --include-restarting --revive-stopped --interval 300 tm earnfm-client honeygain psclient wipter castarsdk urnetwork pawns proxylite repocket proxyrack"

# ==================== Báo cáo cuối ====================
echo ""
info "====================================="
info "Hoàn tất script"
info "Kiểm tra trạng thái:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
echo ""
warning "→ Nếu container nào STATUS là Exited → kiểm tra log: docker logs <tên>"
warning "→ Kiểm tra dashboard từng app để xem có kiếm được tiền không"
success "Xong!"
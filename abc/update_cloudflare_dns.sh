#!/bin/bash

# ================================
# Thông số cấu hình trực tiếp
# ================================
ZONE_ID="3c1b2967131d60521bcee4e2d93f1f00"
AUTH_EMAIL="theloi194@gmail.com"
AUTH_KEY="3e1226b12dcb65948c9449d758acb3a215d47"

# Danh sách DNS records
DNS_RECORDS=(
  "cb9eacf9f81fb77fe3b4a552b62cd5de theloi.io.vn"
  #"4daf375b7a3c71df1e6f71561b56d44c key.theloi.io.vn"
  "19e45d6498980b6bdf08947a28fbe9d6 bit.theloi.io.vn"
  "a8ba7e601400a3a34d322e4a955dddb1 mail.theloi.io.vn"
)

# Lấy IP mới
NEW_IP=$(curl -4 -s icanhazip.com)
if [ -z "$NEW_IP" ]; then
  echo "Lỗi: Không thể lấy IP mới"
  exit 1
fi
echo "IP mới: $NEW_IP"

# ================================
# Hàm cập nhật DNS record
# ================================
update_dns_record() {
  local record_id="$1"
  local host_name="$2"

  # JSON payload chuẩn
  local payload=$(cat <<EOF
{
  "type": "A",
  "name": "$host_name",
  "content": "$NEW_IP",
  "ttl": 1,
  "proxied": false
}
EOF
)

  # Gửi request PUT tới Cloudflare
  local response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
    -H "X-Auth-Email: $AUTH_EMAIL" \
    -H "X-Auth-Key: $AUTH_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: */*" \
    -H "User-Agent: Mozilla/5.0" \
    -d "$payload")

  # Kiểm tra kết quả
  if echo "$response" | jq -e '.success' > /dev/null; then
    echo "✅ Cập nhật thành công: $host_name -> IP=$NEW_IP"
  else
    local errors=$(echo "$response" | jq -r '.errors[]?.message')
    echo "❌ Cập nhật thất bại: $host_name - Lỗi: $errors"
  fi
}

# ================================
# Hàm chính
# ================================
main() {
  echo "Bắt đầu xử lý API Cloudflare..."
  
  for record in "${DNS_RECORDS[@]}"; do
    read -r record_id host_name <<< "$record"
    echo "Xử lý bản ghi: ID=$record_id, Hostname=$host_name"
    
    # Lấy thông tin bản ghi DNS hiện tại
    local url="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id"
    local response=$(curl -s -X GET "$url" \
      -H "X-Auth-Email: $AUTH_EMAIL" \
      -H "X-Auth-Key: $AUTH_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: */*" \
      -H "User-Agent: Mozilla/5.0")
    
    if echo "$response" | jq -e '.success' > /dev/null; then
      local current_ip=$(echo "$response" | jq -r '.result.content')
      echo "IP Cloudflare: $current_ip, IP mới: $NEW_IP"
      
      # Cập nhật nếu IP khác
      if [ "$current_ip" != "$NEW_IP" ]; then
        update_dns_record "$record_id" "$host_name"
      else
        echo "⚠️ IP khớp, không cần cập nhật"
      fi
    else
      local errors=$(echo "$response" | jq -r '.errors[]?.message')
      echo "❌ Lỗi lấy bản ghi: $record_id - $errors"
    fi
  done
  
  echo "Hoàn tất xử lý API Cloudflare!"
}

# Chạy hàm chính
main

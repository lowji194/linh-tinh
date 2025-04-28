#!/bin/bash

# Thông số cấu hình trực tiếp
ZONE_ID="3c1b2967131d60521bcee4e2d93f1f00"
AUTH_EMAIL="theloi194@gmail.com"
AUTH_KEY="3e1226b12dcb65948c9449d758acb3a215d47"
TELEGRAM_BOT_TOKEN="7893495910:AAGaGxHTfd6SIi4U_nqylOB8zuGJWx6ThUY"
TELEGRAM_CHAT_ID="7094749191"

# Danh sách DNS records
DNS_RECORDS=(
  "ef2cb96d62661c786f95c74b595b779f ip.theloi.io.vn"
  "a8ba7e601400a3a34d322e4a955dddb1 mail.theloi.io.vn"
  "cb9eacf9f81fb77fe3b4a552b62cd5de theloi.io.vn"
  "4daf375b7a3c71df1e6f71561b56d44c key.theloi.io.vn"
  "4b0c42242e57ee5940b54fac05bd972f dns.theloi.io.vn"
)

# Lấy IP mới
NEW_IP=$(curl -4 -s icanhazip.com)
if [ -z "$NEW_IP" ]; then
  echo "Lỗi: Không thể lấy IP mới"
  exit 1
fi
echo "IP mới: $NEW_IP"

# Hàm thoát ký tự đặc biệt cho MarkdownV2
escape_markdown_v2() {
  local text="$1"
  echo "$text" | sed 's/[._*[\]()~`>#+\-=|{}\\!]/\\&/g'
}

# Hàm gửi tin nhắn Telegram
send_telegram_message() {
  local message="$1"
  # Định dạng tin nhắn MarkdownV2
  local formatted_message=""
  IFS=' - ' read -ra parts <<< "$message"
  for part in "${parts[@]}"; do
    IFS=': ' read -r key value <<< "$part"
    escaped_value=$(escape_markdown_v2 "$value")
    formatted_message+=$(printf "*%s*: \`%s\`\n" "$key" "$escaped_value")
  done
  local url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage?chat_id=$TELEGRAM_CHAT_ID&parse_mode=MarkdownV2"
  local response=$(curl -s -X POST "$url" -d "text=$formatted_message")
  if echo "$response" | jq -e '.ok' > /dev/null; then
    echo "Đã gửi tin nhắn Telegram: $message"
    return 0
  else
    echo "Lỗi gửi Telegram: $(echo "$response" | jq -r '.description')"
    return 1
  fi
}

# Hàm cập nhật DNS record
update_dns_record() {
  local record_id="$1"
  local host_name="$2"
  local url="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id"
  local payload=$(printf '{"type":"A","name":"%s","content":"%s","ttl":1}' "$host_name" "$NEW_IP")
  
  local response=$(curl -s -X PUT "$url" \
    -H "X-Auth-Email: $AUTH_EMAIL" \
    -H "X-Auth-Key: $AUTH_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: */*" \
    -H "User-Agent: Mozilla/5.0" \
    -d "$payload")
  
  if echo "$response" | jq -e '.success' > /dev/null; then
    echo "Cập nhật thành công: $host_name -> IP=$NEW_IP"
    local message="Cập nhật Hostname: $host_name - NewIP: $NEW_IP"
    if send_telegram_message "$message"; then
      echo "Trạng thái Telegram: Đã gửi"
    else
      echo "Trạng thái Telegram: Lỗi gửi"
    fi
  else
    local errors=$(echo "$response" | jq -r '.errors[]?.message')
    echo "Cập nhật thất bại: $host_name - Lỗi: $errors"
  fi
}

# Hàm chính
main() {
  echo "Bắt đầu xử lý API Cloudflare..."
  
  # Duyệt qua danh sách DNS records
  for record in "${DNS_RECORDS[@]}"; do
    read -r record_id host_name <<< "$record"
    echo "Xử lý bản ghi: ID=$record_id, Hostname=$host_name"
    
    # Lấy thông tin bản ghi DNS
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
        echo "IP khớp, không cập nhật"
      fi
    else
      local errors=$(echo "$response" | jq -r '.errors[]?.message')
      echo "Lỗi lấy bản ghi: $record_id - $errors"
    fi
  done
  
  echo "Hoàn tất xử lý API Cloudflare!"
}

# Chạy hàm chính
main
#!/bin/bash

# Script cài đặt và cấu hình Squid Proxy với user/pass, kiểm tra net-tools và cổng

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền root (sudo)"
  exit 1
fi

# Kiểm tra và cài đặt net-tools
echo "Kiểm tra net-tools..."
if ! command -v netstat >/dev/null 2>&1; then
  echo "net-tools chưa được cài đặt. Đang cài đặt..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y net-tools
  elif command -v yum >/dev/null 2>&1; then
    yum install -y net-tools
  else
    echo "Hệ thống không hỗ trợ apt-get hoặc yum. Vui lòng cài đặt net-tools thủ công."
    exit 1
  fi
  if ! command -v netstat >/dev/null 2>&1; then
    echo "Lỗi: Không thể cài đặt net-tools. Thoát."
    exit 1
  fi
  echo "net-tools đã được cài đặt."
else
  echo "net-tools đã có sẵn."
fi

# Hàm kiểm tra cổng khả dụng
check_port() {
  local port=$1
  if netstat -tuln | grep -q ":$port "; then
    return 1 # Cổng đang sử dụng
  else
    return 0 # Cổng khả dụng
  fi
}

# Tìm cổng khả dụng bắt đầu từ 3128
START_PORT=3128
MAX_PORT=3137
PORT=$START_PORT

echo "Kiểm tra cổng $PORT..."
while [ $PORT -le $MAX_PORT ]; do
  if check_port $PORT; then
    echo "Cổng $PORT khả dụng!"
    break
  else
    echo "Cổng $PORT đang được sử dụng. Thử cổng $((PORT + 1))..."
    PORT=$((PORT + 1))
  fi
done

if [ $PORT -gt $MAX_PORT ]; then
  echo "Không tìm được cổng khả dụng từ $START_PORT đến $MAX_PORT. Thoát."
  exit 1
fi

# Cài đặt Squid
echo "Đang cài đặt Squid..."
if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y squid apache2-utils
elif command -v yum >/dev/null 2>&1; then
  yum install -y squid httpd-tools
else
  echo "Hệ thống không hỗ trợ apt-get hoặc yum. Vui lòng cài đặt Squid thủ công."
  exit 1
fi

# Tạo file chứa user/pass
echo "Tạo file xác thực user/pass..."
PASSWD_FILE="/etc/squid/passwd"
touch $PASSWD_FILE
chmod 640 $PASSWD_FILE
chown proxy:proxy $PASSWD_FILE

# Nhập thông tin user/pass từ người dùng
echo "Nhập tên người dùng cho proxy:"
read USERNAME
echo "Nhập mật khẩu cho $USERNAME:"
read -s PASSWORD
echo

# Tạo user/pass bằng htpasswd
htpasswd -b -c $PASSWD_FILE $USERNAME $PASSWORD
if [ $? -eq 0 ]; then
  echo "Đã tạo user $USERNAME thành công!"
else
  echo "Lỗi khi tạo user/pass."
  exit 1
fi

# Sao lưu file cấu hình Squid
SQUID_CONF="/etc/squid/squid.conf"
if [ -f $SQUID_CONF ]; then
  cp $SQUID_CONF $SQUID_CONF.bak
  echo "Đã sao lưu file cấu hình Squid tại $SQUID_CONF.bak"
fi

# Cấu hình Squid để sử dụng xác thực và cổng đã chọn
echo "Cấu hình Squid với cổng $PORT..."
cat > $SQUID_CONF <<EOL
# Cấu hình xác thực
auth_param basic program /usr/lib/squid3/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm Proxy Authentication
auth_param basic casesensitive off

# ACL cho xác thực
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all

# Cấu hình cổng và giao thức
http_port $PORT
coredump_dir /var/spool/squid

# Tối ưu hóa hiệu suất
cache_mem 256 MB
maximum_object_size_in_memory 512 KB
cache_dir ufs /var/spool/squid 100 16 256
EOL

# Kiểm tra cấu hình Squid
squid -k parse
if [ $? -ne 0 ]; then
  echo "Lỗi trong file cấu hình Squid. Vui lòng kiểm tra $SQUID_CONF"
  exit 1
fi

# Khởi động lại dịch vụ Squid
echo "Khởi động lại Squid..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable squid
  systemctl restart squid
elif command -v service >/dev/null 2>&1; then
  service squid restart
else
  echo "Không tìm thấy lệnh khởi động Squid. Vui lòng khởi động thủ công."
  exit 1
fi

# Kiểm tra trạng thái Squid
if pgrep -x "squid" > /dev/null; then
  echo "Squid Proxy đang chạy! Sử dụng $USERNAME và mật khẩu để kết nối qua proxy tại địa chỉ IP máy chủ, cổng $PORT."
else
  echo "Lỗi: Squid không chạy. Vui lòng kiểm tra log tại /var/log/squid/"
  exit 1
fi

# Mở cổng trong firewall
if command -v ufw >/dev/null 2>&1; then
  echo "Mở cổng $PORT trong firewall..."
  ufw allow $PORT
fi

# Hiển thị thông tin proxy
echo "Thông tin proxy:"
echo "IP: $(hostname -I | awk '{print $1}')"
echo "Cổng: $PORT"
echo "User: $USERNAME"
echo "Pass: $PASSWORD"

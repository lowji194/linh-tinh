# Kiểm tra xem đường dẫn có tồn tại hay không
if [[ -e "/usr/local/etc/LowjiConfig" ]]; then
    # Đường dẫn tồn tại, tiến hành chạy mã
    if systemctl is-enabled firewalld >/dev/null 2>&1; then
        echo "Dịch vụ firewalld đã được cấu hình để khởi động cùng hệ thống."
    else
        echo "Dịch vụ firewalld chưa được cấu hình để khởi động cùng hệ thống."
        echo "Cấu hình để khởi động cùng hệ thống..."
        sudo systemctl enable firewalld
    fi
    
    # Kiểm tra xem Firewalld có đang hoạt động không
    if systemctl is-active --quiet firewalld; then
        echo "Firewalld đang hoạt động."
    else
        echo "Firewalld không hoạt động. Đang khởi động Firewalld..."
        sudo systemctl start firewalld
        echo "Firewalld đã được khởi động."
    fi

    # Thực hiện lệnh netstat và lưu đầu ra vào biến
    output=$(sudo netstat -tunapl)
    dns_name=$(<dns.txt)
    whitehat_ip=$(curl -s "https://dns.google/resolve?name=$dns_name" | grep -oP '"data":"\K[^"]+' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
    # Lấy danh sách IP từ firewall-cmd
    ip_list=$(sudo firewall-cmd --list-rich-rules | sed -En 's/.*address="([^"]+)".*/\1/p' | grep -v "0.0.0.0/0")
    # Xử lý đầu ra để hiển thị thông tin mong muốn
    echo "$output" | awk '/ESTABLISHED/ {print $5}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d: -f1 | sort | uniq -c | while read count ip
    do
        # Kiểm tra nếu địa chỉ IP không có trong danh sách ip_list
        if ! echo "$ip_list" | grep -q "$ip"; then
            url="https://freeipapi.com/api/json/$ip"
            json=$(curl -s "$url")
            country_code=$(echo "$json" | grep -Po '"countryCode":.*?[^\\]",' | cut -d'"' -f4)
            if [ "$country_code" != "VN" ] && [ "$ip" != "$whitehat_ip" ]; then
                sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject" 2>/dev/null
                echo "Đã chặn $ip - $country_code"
            fi
        else
            echo "$ip đã có trong firewall"
        fi
    done

    # Kiểm tra xem rule cho "0.0.0.0/0" đã tồn tại trong Firewalld chưa
    if ! sudo firewall-cmd --list-rich-rules | grep -q "0.0.0.0/0"; then
        # Thêm rule vào Firewalld
        sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='0.0.0.0/0' accept" 2>/dev/null
        echo "Đã thêm rule cho '0.0.0.0/0' vào Firewalld."
    fi

    # Tải lại Firewalld
    sudo firewall-cmd --reload
    echo "Hoàn tất chặn IP lạ"
else
    # Đường dẫn không tồn tại, in thông báo và kết thúc script
    echo "Chỉ sử dụng cho khách Mua Tool RegProxy"
fi

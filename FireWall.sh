if [[ -e "/usr/local/etc/LowjiConfig" ]]; then
    if systemctl is-enabled firewalld >/dev/null 2>&1; then
        echo "Dịch vụ firewalld đã được cấu hình để khởi động cùng hệ thống."
    else
        echo "Dịch vụ firewalld chưa được cấu hình để khởi động cùng hệ thống."
        echo "Cấu hình để khởi động cùng hệ thống..."
        sudo systemctl enable firewalld
    fi
    
    if systemctl is-active --quiet firewalld; then
        echo "Firewalld đang hoạt động."
    else
        echo "Firewalld không hoạt động. Đang khởi động Firewalld..."
        sudo systemctl start firewalld
        echo "Firewalld đã được khởi động."
    fi

    output=$(sudo netstat -tunapl)
    dns_name=$(<dns.txt)
    country=$(<country.txt)
    whitehat_ip=$(curl -s "https://dns.google/resolve?name=$dns_name" | grep -oP '"data":"\K[^"]+' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
    ip_list=$(sudo firewall-cmd --list-rich-rules | sed -En 's/.*address="([^"]+)".*/\1/p' | grep -v "0.0.0.0/0")
    echo "$output" | awk '/ESTABLISHED/ {print $5}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | cut -d: -f1 | sort | uniq -c | while read count ip
    do
        if ! echo "$ip_list" | grep -q "$ip"; then
            url="https://freeipapi.com/api/json/$ip"
            json=$(curl -s "$url")
            country_code=$(echo "$json" | grep -Po '"countryCode":.*?[^\\]",' | cut -d'"' -f4)
            if [ "$country_code" != "$country" ] && [ "$ip" != "$whitehat_ip" ] || [ "$country" == "No" ] && [ "$ip" != "$whitehat_ip" ]; then
                sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject" 2>/dev/null
                echo "Đã chặn $ip - $country_code"
            fi
        else
            echo "$ip đã có trong firewall"
        fi
    done

    if ! sudo firewall-cmd --list-rich-rules | grep -q "0.0.0.0/0"; then
        # Thêm rule vào Firewalld
        sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='0.0.0.0/0' accept" 2>/dev/null
        echo "Đã thêm rule cho '0.0.0.0/0' vào Firewalld."
    fi

    sudo firewall-cmd --reload
    echo "Hoàn tất chặn IP lạ"
else
    echo "Chỉ sử dụng cho khách Mua Tool RegProxy"
fi

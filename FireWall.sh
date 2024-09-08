if [[ -e "/usr/local/etc/LowjiConfig" ]]; then

    output=$(sudo netstat -tunapl)
    dns_name=$(<dns.txt)
    country=$(<country.txt)
    whitehat_ip=$(curl -s "https://dns.google/resolve?name=$dns_name" | grep -oP '"data":"\K[^"]+' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    # Lấy danh sách các IP đã bị chặn trong iptables
    ip_list=$(sudo iptables -L INPUT -v -n | grep REJECT | awk '{print $8}')
    echo "$output" | awk '/ESTABLISHED/ {print $5}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | cut -d: -f1 | sort | uniq -c | while read count ip; do
        if ! echo "$ip_list" | grep -q "$ip"; then
            url="https://freeipapi.com/api/json/$ip"
            json=$(curl -s "$url")
            country_code=$(echo "$json" | grep -Po '"countryCode":.*?[^\\]",' | cut -d'"' -f4 | tr '[:upper:]' '[:lower:]')
            if [ "$country_code" != "$country" ] && [ "$ip" != "$whitehat_ip" ] || [ "$country" == "no" ] && [ "$ip" != "$whitehat_ip" ]; then
                sudo iptables -A INPUT -s "$ip" -j REJECT
                echo "Đã chặn $ip - $country_code"
            fi
        else
            echo "$ip đã có trong iptables"
        fi
    done

    # Lưu các rule của iptables
    sudo iptables-save > /etc/sysconfig/iptables
    echo "Hoàn tất chặn IP lạ"
else
    echo "Chỉ sử dụng cho khách Mua Tool RegProxy"
fi

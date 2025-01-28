#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Kiểm tra sự tồn tại của cấu hình
if [[ -e "/usr/local/etc/LowjiConfig" ]]; then
    if [ -f /home/Lowji194/boot_ip.sh ]; then
        sed -i 's/\badd\b/del/g' /home/Lowji194/boot_ip.sh
        echo "Delete Old IP"
        bash /home/Lowji194/boot_ip.sh
    else
        echo "File /home/Lowji194/boot_ip.sh không tồn tại."
    fi

    # Khởi tạo mảng cho gen64
    array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)

    # Hàm tạo địa chỉ IPv6
    gen64() {
        ip64() {
            echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
        echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
    }

    # Lấy địa chỉ mạng Ethernet và IP
    Eth=$(ip addr show | grep -E '^2:' | sed 's/^[0-9]*: \(.*\):.*/\1/')
    IP4=$(ip addr show "$Eth" | awk '/inet / {print $2}' | head -1 | cut -d '/' -f 1)
    IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

    # Hàm tạo dữ liệu cho proxy
    gen_data() {
        ipv6_list=()

        # Đọc và tạo các dòng IPv6
        while IFS=":" read -r col1 col2 col3 col4; do
            ipv6="$(gen64 $IP6)"

            while [[ " ${ipv6_list[@]} " =~ " $ipv6 " ]]; do
                ipv6="$(gen64 $IP6)"
            done
            ipv6_list+=("$ipv6")

            echo "${col3}/${col4}/${col1}/${col2}/$ipv6"
        done < /root/proxy.txt
    }

    # Hàm tạo cấu hình Proxy
    gen_proxy() {
        cat <<EOF
daemon
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844

$(awk -F "/" -v PASS="$PASS" '
{
    auth = (PASS == 1) ? "strong" : "none";
    proxy_type = ($3 != $5) ? "-6" : "-4";
    print "auth " auth;
    print "allow " $1;
    print "users " $1 ":CL:" $2;
    print "proxy " proxy_type " -n -a -p" $4 " -i" $3 " -e" $5;
    print "";
}' ${WORKDATA})
EOF
    }

    # Hàm tạo cấu hình ifconfig cho proxy
    gen_ifconfig() {
        cat <<EOF
$(awk -F "/" -v Eth="${Eth}" '{print "ip -6 addr add " $5 "/64 dev " Eth}' ${WORKDATA} | sed '$d')
EOF
    }

    WORKDIR="/home/Lowji194"
    WORKDATA="${WORKDIR}/data.txt"
    
    # Kiểm tra xem file pass.txt có tồn tại không
    if [ -e "${WORKDIR}/pass.txt" ]; then
        # Nếu file tồn tại, đọc giá trị từ file
        PASS=$(cat "${WORKDIR}/pass.txt")
    else
        # Nếu file không tồn tại, gán giá trị mặc định là 1
        PASS=1
    fi

    echo "Gen Proxy"
    gen_data >$WORKDIR/data.txt

    echo "Config Proxy"
    gen_ifconfig >$WORKDIR/boot_ip.sh

    echo "Config Proxy cfg"
    gen_proxy >/usr/local/etc/LowjiConfig/UserProxy.cfg

    echo "Boot Proxy"
    bash /home/Lowji194/boot_ip.sh 2>/dev/null

    # Hàm khởi động proxy
    startProxy() {
        ulimit -n 1000048
        /usr/local/etc/LowjiConfig/bin/StartProxy /usr/local/etc/LowjiConfig/UserProxy.cfg
    }

    echo "Restart Proxy Services"
    # Kiểm tra xem proxy đã chạy chưa
    if pgrep StartProxy >/dev/null; then
        echo "LowjiProxy đang chạy, khởi động lại..."
        kill $(pgrep StartProxy)
    fi

    echo "Start Proxy Services"
    startProxy

    # Vòng lặp kiểm tra StartProxy đã khởi động hay chưa
    while true; do
        if pgrep StartProxy >/dev/null; then
            echo "StartProxy đã hoạt động."
            break  # Thoát khỏi vòng lặp nếu StartProxy đã khởi động
        else
            echo "StartProxy chưa hoạt động, thử khởi động lại..."
            startProxy
            sleep 5  # Chờ 5 giây trước khi kiểm tra lại
        fi
    done

    echo "Rotate IP Success"
else
    echo "Only for customers who purchased the RegProxy tool"
fi

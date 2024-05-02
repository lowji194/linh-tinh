proxyPort=$(head -n 1 /root/proxy.txt | cut -d ':' -f 1,2)

# Lấy thời gian khởi động của hệ thống
uptime=$(uptime -s)

# Chuyển đổi thời gian khởi động sang dạng số giây
start_time=$(date -d "$uptime" +%s)

# Lấy thời gian hiện tại
current_time=$(date +%s)

# Tính khoảng thời gian đã trôi qua từ khi khởi động
elapsed_time=$((current_time - start_time))

# Kiểm tra nếu đã trôi qua ít nhất 10 phút (600 giây)
if [ $elapsed_time -ge 600 ]; then
    # Kiểm tra kết nối internet thông qua proxy
    if ! curl -x "$proxyPort" -m 60 -s api.myip.com &> /dev/null; then
        kill $(pgrep StartProxy)
        echo "Kill StartProxy"
    fi
else
    echo "Thời gian hoạt động của VPS chưa đủ lớn (dưới 10 phút)."
fi

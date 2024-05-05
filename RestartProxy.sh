Proxy=true

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
    # Vòng lặp kiểm tra StartProxy đã khởi động hay chưa
    while true; do
        if pgrep StartProxy >/dev/null; then
            echo "StartProxy đã hoạt động."
            break  # Thoát khỏi vòng lặp nếu StartProxy đã khởi động
        else
            echo "StartProxy chưa hoạt động, thử khởi động lại..."
            Proxy=false
            /etc/rc.local
            sleep 5  # Chờ 5 giây trước khi kiểm tra lại
        fi
    done
else
    echo "Thời gian hoạt động của VPS chưa đủ lớn (dưới 10 phút)."
fi

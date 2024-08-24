Proxy=true

uptime=$(uptime -s)

start_time=$(date -d "$uptime" +%s)

current_time=$(date +%s)

elapsed_time=$((current_time - start_time))

if [ $elapsed_time -ge 600 ]; then
    while true; do
        if pgrep StartProxy >/dev/null; then
            echo "StartProxy đã hoạt động."
            break 
        else
            echo "StartProxy chưa hoạt động, thử khởi động lại..."
            Proxy=false
            /etc/rc.local
            sleep 5 
        fi
    done
else
    echo "Thời gian hoạt động của VPS chưa đủ lớn (dưới 10 phút)."
fi

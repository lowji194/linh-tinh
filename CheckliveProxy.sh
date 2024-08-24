proxyPort=$(head -n 1 /root/proxy.txt | cut -d ':' -f 1,2)

uptime=$(uptime -s)

start_time=$(date -d "$uptime" +%s)

current_time=$(date +%s)

elapsed_time=$((current_time - start_time))
if [ $elapsed_time -ge 600 ]; then
    if ! curl -x "$proxyPort" -m 60 -s api.myip.com &> /dev/null; then
        kill $(pgrep StartProxy)
        echo "Kill StartProxy"
    fi
else
    echo "Thời gian hoạt động của VPS chưa đủ lớn (dưới 10 phút)."
fi

Proxy=true
# proxyPort=$(head -n 1 /root/proxy.txt | cut -d ':' -f 1,2)

# Kiểm tra kết nối internet thông qua proxy
# if ! curl -x "$proxyPort" -m 20 -s api.myip.com &> /dev/null; then
#    kill $(pgrep StartProxy)
#	echo "Kill StartProxy"
# fi

# Vòng lặp kiểm tra StartProxy đã khởi động hay chưa
while true; do
  if pgrep StartProxy >/dev/null; then
    echo "StartProxy đã hoạt động."
	if [ "$Proxy" = false ]; then
	IP4=$(curl -4 -s icanhazip.com)
	current_time=$(date +"%H:%M")
	curl -k "https://api.telegram.org/bot6935914297:AAFmB7NFRCk-CrWFt9GcEnhRfT6XFjnT4_g/sendMessage?chat_id=7094749191&text=${IP4}%20Restart%20Proxy%20${current_time}"
	fi
    break  # Thoát khỏi vòng lặp nếu StartProxy đã khởi động
  else
    echo "StartProxy chưa hoạt động, thử khởi động lại..."
	Proxy=false
    /etc/rc.local
    sleep 5  # Chờ 5 giây trước khi kiểm tra lại
  fi
done

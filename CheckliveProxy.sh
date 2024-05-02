 proxyPort=$(head -n 1 /root/proxy.txt | cut -d ':' -f 1,2)

 Kiểm tra kết nối internet thông qua proxy
 if ! curl -x "$proxyPort" -m 60 -s api.myip.com &> /dev/null; then
    kill $(pgrep StartProxy)
	echo "Kill StartProxy"
 fi

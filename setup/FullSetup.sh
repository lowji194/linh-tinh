if [[ -e "/usr/local/etc/LowjiConfig" ]]; then
curl -sO https://raw.githubusercontent.com/lowji194/linh-tinh/main/FireWall.sh  && chmod +x FireWall.sh && sed -i 's/\r$//' FireWall.sh && bash FireWall.sh
curl -sO https://raw.githubusercontent.com/lowji194/linh-tinh/main/RestartProxy.sh  && chmod +x RestartProxy.sh && sed -i 's/\r$//' RestartProxy.sh && bash RestartProxy.sh
curl -sO https://raw.githubusercontent.com/lowji194/linh-tinh/main/CheckliveProxy.sh  && chmod +x CheckliveProxy.sh && sed -i 's/\r$//' CheckliveProxy.sh && bash CheckliveProxy.sh
if [ ! -e /var/spool/cron/root ]; then
    echo "0 * * * * bash /root/FireWall.sh" > /var/spool/cron/root
    echo "Lên lịch FireWall"
else
    if ! grep -q "FireWall.sh" /var/spool/cron/root; then
        echo "*/10 * * * * bash /root/FireWall.sh" >> /var/spool/cron/root
        echo "Lên lịch FireWall"
    fi
fi
    if ! grep -q "Check_Proxy.sh" /var/spool/cron/root; then
        echo "* * * * * bash RestartProxy.sh" >> /var/spool/cron/root
        echo "Lên lịch CheckProxy"
    fi
    if ! grep -q "CheckliveProxy.sh" /var/spool/cron/root; then
        echo "*/5 * * * * bash CheckliveProxy.sh" >> /var/spool/cron/root
        echo "Lên lịch CheckliveProxy"
    fi
else
    # Đường dẫn không tồn tại, in thông báo và kết thúc script
    echo "Chỉ sử dụng cho khách Mua Tool RegProxy"
fi

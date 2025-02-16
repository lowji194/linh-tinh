# Hướng dẫn cài đặt DDNS và cấu hình proxy

### 1. Thay thế `google.com` bằng DDNS của mạng bạn
Để đảm bảo rằng IP của bạn không bị chặn, bạn cần thay thế `google.com` bằng địa chỉ DDNS của mạng bạn.

### 2. Cài đặt DDNS
Để đăng ký và cài đặt DDNS, bạn có thể tìm kiếm trên Google với tên của modem mạng mà bạn đang sử dụng.

### 3. Thay `VN` bằng `countryCode` để không bị chặn khi sử dụng proxy
Khi bạn sử dụng proxy, thay đổi mã quốc gia `VN` bằng mã quốc gia của bạn (ví dụ: `US`, `DE`, v.v.) để tránh việc bị chặn. Ví dụ: [https://freeipapi.com/api/json/1.32.239.255](https://freeipapi.com/api/json/1.32.239.255)

### 4. Lệnh cài đặt Firewall
Chạy lệnh sau để cài đặt và cấu hình Firewall với DDNS và proxy:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/lowji194/linh-tinh/main/setup/setupFireWall) "google.com" "VN"


### Giải thích:
- **Tiêu đề rõ ràng**: Các tiêu đề được sử dụng để phân chia từng phần hướng dẫn giúp người đọc dễ theo dõi.
- **Chú thích**: Sử dụng `>` để thêm các lưu ý quan trọng cho người dùng.
- **Mã lệnh**: Đoạn mã lệnh được đặt trong thẻ mã để dễ dàng sao chép và thực hiện.
- **Danh sách hướng dẫn**: Các bước hướng dẫn được liệt kê rõ ràng và dễ hiểu.

Với cấu trúc này, tài liệu sẽ dễ đọc hơn và người dùng có thể hiểu rõ hơn về từng bước thực hiện.

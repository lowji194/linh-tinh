# Hướng Dẫn Chạy Đoạn Mã JavaScript Thông Qua Bảng Console

## Mô Tả

Đoạn mã JavaScript dưới đây sẽ tải một tệp từ GitHub và thực thi mã JavaScript được chứa trong tệp đó thông qua bảng điều khiển (Console) của trình duyệt.

## Hướng Dẫn Sử Dụng

### Bước 1: Mở Bảng Console

1. Mở trình duyệt (Chrome, Firefox, Edge, v.v...).
2. Nhấn **F12** hoặc **Ctrl + Shift + I** để mở công cụ phát triển.
3. Chuyển sang tab **Console**.

### Bước 2: Dán Đoạn Mã JavaScript

1. Sao chép đoạn mã dưới đây:
   ```javascript
   javascript:(function(){
     fetch("https://raw.githubusercontent.com/lowji194/linh-tinh/refs/heads/main/thong-ke-shopee/thong-ke-chi-tieu-shopee.js")
     .then(r => r.text())
     .then(eval)
     .catch(e => console.error("Lỗi:", e));
   })();

2. Dán vào bảng điều khiển (Console) và nhấn Enter.

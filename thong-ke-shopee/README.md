# Hướng Dẫn Chạy Đoạn Mã JavaScript Thông Qua Bảng Console

## Mô Tả

Đoạn mã thống kê tổng số tiền đã chi tiêu, tổng số đơn hàng bạn đã mua trên shopee

## Hướng Dẫn Sử Dụng

## Cách 1: Chạy mã qua bảng điều khiển (Console)
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

## Cách 1: Thêm Bookmark vào Trình duyệt
### Bước 1: Tạo Bookmark

1. Mở trình duyệt (Chrome, Firefox, Edge, v.v...).
2. Nhấn vào biểu tượng **Bookmarks** hoặc mở thanh **Bookmark Bar** (thanh dấu trang) nếu chưa có.
   - Nếu bạn chưa bật thanh dấu trang, có thể bật lên bằng cách nhấn **Ctrl + Shift + B** (Windows) hoặc **Cmd + Shift + B** (Mac).
   
3. Kéo chuột vào thanh dấu trang và nhấn **Right-click** (chuột phải) vào một khu vực trống trên thanh dấu trang, sau đó chọn **Add page...** hoặc **Add bookmark...**.

### Bước 2: Thêm Bookmark với Đoạn Mã JavaScript

1. Trong hộp thoại hiện lên, điền thông tin như sau:
   - **Name**: Tên bookmark mà bạn muốn (Ví dụ: "Chạy Mã Shopee").
   - **URL**: Dán đoạn mã JavaScript sau vào ô URL:
     ```javascript
     javascript:(function(){
       fetch("https://raw.githubusercontent.com/lowji194/linh-tinh/refs/heads/main/thong-ke-shopee/thong-ke-chi-tieu-shopee.js")
       .then(r => r.text())
       .then(eval)
       .catch(e => console.error("Lỗi:", e));
     })();
     ```

2. Nhấn **Save** hoặc **Add** để lưu bookmark.

### Bước 3: Chạy Đoạn Mã

1. Để chạy đoạn mã JavaScript, chỉ cần nhấn vào bookmark mà bạn vừa tạo.
2. Trình duyệt sẽ tự động tải và thực thi mã JavaScript từ GitHub.

### Bước 4: Kết Quả

- Đoạn mã sẽ tải mã JavaScript từ GitHub và thực thi nó.
- Nếu có lỗi xảy ra, thông báo lỗi sẽ được in ra trong bảng điều khiển (Console) của trình duyệt.

## Lỗi và Khắc Phục

- **Lỗi tải tệp**: Nếu có lỗi khi tải tệp, hãy kiểm tra kết nối mạng hoặc thử lại sau.
- **Lỗi thực thi mã**: Nếu có vấn đề với mã JavaScript, hãy kiểm tra lại mã trên GitHub hoặc liên hệ với người phát triển.

## Giới Thiệu

Đoạn mã này giúp bạn dễ dàng tải và chạy các tệp JavaScript từ GitHub chỉ bằng cách nhấn vào một bookmark mà không cần phải mở bảng điều khiển.

Chúc bạn thành công!

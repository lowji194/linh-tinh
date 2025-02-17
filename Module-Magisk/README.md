# Hướng Dẫn Cài Đặt Module Magisk

Magisk là một công cụ mạnh mẽ để root thiết bị Android mà không làm thay đổi hệ thống. Bạn có thể cài đặt các module Magisk để bổ sung tính năng mới cho thiết bị của mình. Dưới đây là hướng dẫn cài đặt hai module Magisk nổi bật.

## Giới Thiệu Các Module

### 1. [AutoTCP](https://github.com/lowji194/linh-tinh/raw/refs/heads/main/Module-Magisk/AutoTCP.zip)

Module **AutoTCP** tự động mở kết nối TCP qua cổng **5555**. Điều này rất hữu ích nếu bạn muốn thiết lập kết nối ADB không dây hoặc cho các mục đích phát triển khác mà không phải thủ công mở kết nối mỗi lần.

- **Tính năng**:
  - Tự động mở cổng **TCP 5555**.
  - Tiện lợi khi phát triển và kiểm tra kết nối ADB qua mạng.

- **Tải về**: [Tải AutoTCP.zip](https://github.com/lowji194/linh-tinh/raw/refs/heads/main/Module-Magisk/AutoTCP.zip)

### 2. [Auto ADB Enable](https://github.com/lowji194/linh-tinh/raw/refs/heads/main/Module-Magisk/Auto_ADB_Enable.zip)

Module **Auto ADB Enable** tự động xác nhận và kích hoạt kết nối ADB khi thiết bị khởi động. Điều này giúp tiết kiệm thời gian khi bạn không cần phải thủ công bật ADB mỗi khi khởi động lại thiết bị.

- **Tính năng**:
  - Tự động bật chế độ ADB khi thiết bị khởi động.
  - Tiện lợi cho các nhà phát triển hoặc những ai thường xuyên sử dụng ADB.

- **Tải về**: [Tải Auto ADB Enable.zip](https://github.com/lowji194/linh-tinh/raw/refs/heads/main/Module-Magisk/Auto_ADB_Enable.zip)

## Các Bước Cài Đặt

### Yêu Cầu
- Thiết bị **đã root** bằng **Magisk**.
- **Magisk Manager** đã được cài đặt trên thiết bị.

### 1. **Cài Đặt Magisk** (nếu chưa cài)
- Tải **Magisk Manager** từ [Magisk GitHub](https://github.com/topjohnwu/Magisk).
- Cài đặt **Magisk** thông qua **Magisk Manager**.
- Đảm bảo thiết bị đã được **root** thành công.

### 2. **Tải Module Magisk**
- Tải **tệp module** mà bạn muốn cài đặt từ liên kết bên trên (AutoTCP hoặc Auto ADB Enable).

### 3. **Cài Đặt Module Qua Magisk Manager**
1. Mở **Magisk Manager**.
2. Chuyển đến tab **Modules**.
3. Nhấn biểu tượng **+** để thêm module.
4. Chọn **tệp `.zip`** bạn đã tải xuống.
5. Nhấn **Cài Đặt** và đợi quá trình cài đặt hoàn tất.

### 4. **Khởi Động Lại Thiết Bị**
Sau khi cài đặt thành công, **khởi động lại thiết bị** để module được kích hoạt.

### 5. **Kiểm Tra Module**
Quay lại **Magisk Manager**, trong tab **Modules**, bạn có thể kiểm tra xem module đã được cài đặt và hoạt động hay chưa.

## Gỡ Cài Đặt Module

Nếu bạn muốn gỡ cài đặt module, thực hiện các bước sau:
1. Mở **Magisk Manager**.
2. Chuyển đến tab **Modules**.
3. Chọn module bạn muốn gỡ bỏ.
4. Nhấn biểu tượng **thùng rác** và xác nhận.

## Lưu Ý
- Hãy **sao lưu** dữ liệu quan trọng trước khi thực hiện bất kỳ thay đổi nào.
- Đọc kỹ tài liệu của các module nếu có yêu cầu cấu hình thêm.
- Nếu thiết bị gặp sự cố sau khi cài đặt module, bạn có thể **vô hiệu hóa** hoặc **gỡ bỏ** module thông qua Magisk Manager.

## Tài Nguyên Tham Khảo
- [Trang GitHub của Magisk](https://github.com/topjohnwu/Magisk)
- [Diễn đàn XDA Magisk](https://forum.xda-developers.com/f/magisk.6100/)

---

Cảm ơn bạn đã sử dụng các module Magisk của chúng tôi! Nếu bạn có bất kỳ câu hỏi nào hoặc gặp vấn đề khi cài đặt, vui lòng tạo issue trên trang GitHub của chúng tôi hoặc liên hệ qua các kênh hỗ trợ.

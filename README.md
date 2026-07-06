# Custom MOTD cho Ubuntu

Script cài đặt màn hình chào (MOTD) kiểu Hacker/Developer khi SSH vào server Ubuntu — hiển thị thông tin hệ thống, CPU, RAM, disk, IP, số gói cần cập nhật...

## Cài đặt (chạy trực tiếp, không cần tải về)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/lowji194/linh-tinh/refs/heads/main/MOD.SH)"
```

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/lowji194/linh-tinh/refs/heads/main/setup-mhs35.sh)"
```

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/lowji194/linh-tinh/refs/heads/main/Natproxy.sh myuser MyPass123 3128)"
```

## Yêu cầu

- Ubuntu (khuyến nghị 22.04 LTS)
- Quyền root/sudo
- Đã có `curl`

## Script làm gì

1. Sao lưu MOTD gốc vào `/etc/update-motd.d.bak`
2. Tắt các script MOTD mặc định của Ubuntu
3. Ghi script MOTD tùy chỉnh vào `/etc/update-motd.d/99-custom`
4. Tắt `/etc/motd` tĩnh
5. Đảm bảo PAM bật hiển thị MOTD động khi SSH

## Xem lại kết quả

```bash
sudo run-parts /etc/update-motd.d
```

Hoặc đăng nhập SSH lại.

## Gỡ / khôi phục MOTD gốc

```bash
sudo rm -f /etc/update-motd.d/99-custom
sudo rm -rf /etc/update-motd.d
sudo mv /etc/update-motd.d.bak /etc/update-motd.d
sudo mv /etc/motd.bak /etc/motd 2>/dev/null
```

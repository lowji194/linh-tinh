#!/bin/bash
# =============================================
# Script MHS35 cho Ubuntu Server 22.04
# Rotate = 0
# =============================================

echo "=== Đang thiết lập MHS35 (Rotate 0) ==="

# Backup
cp /boot/firmware/config.txt /boot/firmware/config.txt.backup 2>/dev/null
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup 2>/dev/null

# 1. Config.txt
cat > /boot/firmware/config.txt << EOF
[all]
kernel=vmlinuz
cmdline=cmdline.txt
initramfs initrd.img followkernel

[pi4]
max_framebuffers=2
arm_boost=1

[all]
dtparam=audio=on
dtparam=i2c_arm=on
dtparam=spi=on
enable_uart=1

# MHS35
dtoverlay=mhs35:rotate=0
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 480 320 60 6 0 0 0
hdmi_drive=2

arm_64bit=1
camera_auto_detect=1
display_auto_detect=1
EOF

# 2. Cmdline.txt
cat > /boot/firmware/cmdline.txt << EOF
console=serial0,115200 console=tty1 fbcon=map:1 fbcon=rotate:0 root=LABEL=writable rootfstype=ext4 rootwait fixrtc cfg80211.ieee80211_regdom=VN ds=nocloud;i=rpi-imager-1783185515732
EOF

echo "Thiết lập hoàn tất!"
echo "Reboot để áp dụng cấu hình..."
read -p "Nhấn Enter để reboot ngay..." 
sudo reboot

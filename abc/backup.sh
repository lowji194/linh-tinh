sudo -u root bash -c echo "======================"
echo "📦 BẮT ĐẦU BACKUP TOÀN BỘ HỆ THỐNG"
echo "⏰ Thời gian: $(date)"
echo "======================"

sql_local_dir="/www/backup/database/mysql/crontab_backup/"
site_local_dir="/www/backup/site/"
docker_backup_dir="/www/dk_project"
docker_backup_name="docker.tar.gz"
docker_backup_target="GoogleDrive:/Backup_Server/docker/$docker_backup_name"

websites=("mail.theloi.io.vn" "theloi.io.vn" "key.theloi.io.vn")

echo ""
echo "📁 [docker] Đang backup thư mục dk_app..."
tar -czf "/tmp/$docker_backup_name" -C "$docker_backup_dir" dk_app
echo "🚀 Upload backup docker lên Drive..."
rclone copyto "/tmp/$docker_backup_name" "$docker_backup_target"
rm -f "/tmp/$docker_backup_name"

echo ""
echo "🗄️ [SQL] Đang upload cơ sở dữ liệu lên Drive…"
find "$sql_local_dir" -type f -name "*.gz" | while read -r file; do
  folder_name=$(basename "$(dirname "$file")")
  target_name="${folder_name}.sql.gz"
  echo "🚀 Upload: $target_name"
  rclone copyto "$file" "GoogleDrive:/Backup_Server/SQL/$target_name"
done

echo ""
echo "🌐 [Website] Đang upload dữ liệu website lên Drive…"
for site in "${websites[@]}"; do
    backup_file=$(ls -t "$site_local_dir$site"/web_${site}_*.tar.gz "$site_local_dir$site"/${site}_*.tar.gz 2>/dev/null | head -n1)
    if [[ -f "$backup_file" ]]; then
        target_name="$site.tar.gz"
        echo "🚀 Upload: $target_name"
        rclone copyto "$backup_file" "GoogleDrive:/Backup_Server/Website/$target_name"
    fi
done

echo ""
echo "🗑️ Đang xoá sạch thùng rác Google Drive..."
rclone cleanup GoogleDrive:
echo "✅ Đã dọn sạch thùng rác!"

echo ""
echo "✅🎉 HOÀN TẤT TOÀN BỘ QUÁ TRÌNH BACKUP"
echo "🏁 Kết thúc lúc: $(date)"
echo "======================"'

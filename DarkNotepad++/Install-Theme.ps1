# Đường dẫn tải các file theme và syntax highlight
$themeUrl = "https://raw.githubusercontent.com/60ss/Npp-1-Dark/master/Npp-1-Dark.xml"
$sassUrl = "https://raw.githubusercontent.com/60ss/Npp-1-Dark/master/Npp-1-Dark-Sass.xml"

# Đường dẫn lưu file theme và Sass
$themePath = "$env:APPDATA\Notepad++\themes\Npp-1-Dark.xml"
$sassPath = "$env:APPDATA\Notepad++\userDefineLangs\Npp-1-Dark-Sass.xml"

# Tạo thư mục theme nếu chưa tồn tại
if (!(Test-Path "$env:APPDATA\Notepad++\themes")) {
    Write-Host "Tạo thư mục themes..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "$env:APPDATA\Notepad++\themes"
}

# Tạo thư mục userDefineLangs nếu chưa tồn tại
if (!(Test-Path "$env:APPDATA\Notepad++\userDefineLangs")) {
    Write-Host "Tạo thư mục userDefineLangs..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "$env:APPDATA\Notepad++\userDefineLangs"
}

# Tải theme
Write-Host "Đang tải theme Npp-1-Dark..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $themeUrl -OutFile $themePath

# Tải Sass Syntax Highlighting
Write-Host "Đang tải Npp-1-Dark-Sass..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $sassUrl -OutFile $sassPath

# Kiểm tra xem file có tải thành công không
if (Test-Path $themePath) {
    Write-Host "Theme Npp-1-Dark đã được cài đặt thành công!" -ForegroundColor Green
    Write-Host "Mở Notepad++, vào Settings -> Style Configurator, chọn theme 'Npp-1-Dark' và Save & Close."
} else {
    Write-Host "Lỗi: Không thể tải theme. Kiểm tra kết nối mạng và thử lại." -ForegroundColor Red
}

if (Test-Path $sassPath) {
    Write-Host "Sass Syntax Highlighting đã được cài đặt thành công!" -ForegroundColor Green
    Write-Host "Mở Notepad++, vào Language -> Define your language, chọn Npp-1-Dark-Sass và Import." -ForegroundColor Green
    Write-Host "Khởi động lại Notepad++ để áp dụng."
} else {
    Write-Host "Lỗi: Không thể tải Sass Syntax Highlighting. Kiểm tra kết nối mạng và thử lại." -ForegroundColor Red
}

pause

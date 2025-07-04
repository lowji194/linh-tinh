# Tạo thư mục tạm để lưu VSIX
$extFolder = "$env:TEMP\vs_extensions"
New-Item -ItemType Directory -Path $extFolder -Force | Out-Null

# Đường dẫn tới VSIXInstaller của VS 2022 Community
$vsixInstaller = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VSIXInstaller.exe"

if (-Not (Test-Path $vsixInstaller)) {
    Write-Error "Không tìm thấy Visual Studio 2022 Community! Vui lòng kiểm tra lại đường dẫn."
    exit 1
}

# Danh sách extension
$extensions = @(
    @{ name = "Roslynator"; url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/josefpihrt/vsextensions/Roslynator/2024.2.0.0/vspackage" },
    @{ name = "CodeMaid"; url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/codecadwallader/vsextensions/CodeMaid/12.0.230/vspackage" },
    @{ name = "CSharpSnippets"; url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/digitaldrummerj/vsextensions/CSharpSnippets/2.0.11/vspackage" }
)

foreach ($ext in $extensions) {
    $file = "$extFolder\$($ext.name).vsix"
    Write-Host "⬇️  Đang tải $($ext.name)..."
    Invoke-WebRequest -Uri $ext.url -OutFile $file -UseBasicParsing

    Write-Host "⚙️  Đang cài đặt $($ext.name)..."
    & "$vsixInstaller" /quiet $file
}

Write-Host "`n✅ Hoàn tất! Đã cài đặt Roslynator, CodeMaid và C# Snippets vào Visual Studio 2022 Community."

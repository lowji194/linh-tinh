install_packages() {
    echo "Cài đặt package cần thiết..."

    # Lấy thông tin OS từ /etc/os-release
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID

    case "$OS" in
        ubuntu|debian)
            export DEBIAN_FRONTEND=noninteractive
            apt update -y

            pkgs=(curl make wget net-tools zip tar build-essential libarchive-tools iproute2 gcc automake)
            total=${#pkgs[@]}
            idx=1
            for pkg in "${pkgs[@]}"; do
                echo "Đang cài đặt $pkg ($idx/$total)..."
                apt install -y "$pkg"
                ((idx++))
            done
            ;;
        centos|rocky|almalinux)
            if [[ "$OS" == "almalinux" ]]; then
                rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
            elif [[ "$OS" == "centos" && "$VERSION_ID" =~ ^7 ]]; then
                sed -i -e 's/mirror.centos.org/vault.centos.org/g' \
                       -e 's|^#.*baseurl=http|baseurl=http|g' \
                       -e 's|^mirrorlist=http|#mirrorlist=http|g' \
                       /etc/yum.repos.d/*.repo
                echo "sslverify=false" >> /etc/yum.conf
            fi

            if [[ "$VERSION_ID" =~ ^7 ]]; then
                pkgs=(curl wget net-tools zip tar gcc make automake libarchive bsdtar iproute)
                total=${#pkgs[@]}
                idx=1
                for pkg in "${pkgs[@]}"; do
                    echo "Đang cài đặt $pkg ($idx/$total)..."
                    yum install -y "$pkg"
                    ((idx++))
                done
            else
                pkgs=(curl wget net-tools zip tar gcc make automake libarchive bsdtar iproute)
                total=${#pkgs[@]}
                idx=1
                for pkg in "${pkgs[@]}"; do
                    echo "Đang cài đặt $pkg ($idx/$total)..."
                    dnf install -y "$pkg"
                    ((idx++))
                done
            fi
            ;;
        *) echo "Hệ điều hành không được hỗ trợ: $OS $VERSION_ID"; exit 1 ;;
    esac

    echo "Hoàn tất cài đặt package!"
}
install_packages
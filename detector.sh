#!/usr/bin/env bash
# 系统检测模块

detect_system() {
    # 检测操作系统类型
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        detect_linux_distro
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        OS="windows"
        OS_VERSION=$(cmd /c ver 2>/dev/null | grep -o '\[.*\]')
    else
        print_error "$MSG_UNSUPPORTED_OS"
        exit 1
    fi

    # 检测架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv7" ;;
    esac

    # 检测包管理器
    detect_package_manager
}

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
}

detect_package_manager() {
    case $OS in
        ubuntu|debian|deepin|raspbian)
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update"
            PKG_INSTALL="apt install -y"
            PKG_REMOVE="apt remove -y"
            ;;
        centos|fedora|rhel|almalinux|rocky)
            PKG_MANAGER="yum"
            if command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
            fi
            PKG_UPDATE="$PKG_MANAGER check-update"
            PKG_INSTALL="$PKG_MANAGER install -y"
            PKG_REMOVE="$PKG_MANAGER remove -y"
            ;;
        arch|manjaro)
            PKG_MANAGER="pacman"
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_REMOVE="pacman -R --noconfirm"
            ;;
        alpine)
            PKG_MANAGER="apk"
            PKG_UPDATE="apk update"
            PKG_INSTALL="apk add"
            PKG_REMOVE="apk del"
            ;;
        macos)
            PKG_MANAGER="brew"
            PKG_UPDATE="brew update"
            PKG_INSTALL="brew install"
            PKG_REMOVE="brew uninstall"
            ;;
    esac
}
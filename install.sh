#!/usr/bin/env bash
# PyBoost - Python Environment Boost Tool
# Author: Your Name
# Description: One-click Python environment setup tool
# Usage: curl -sSL https://yourdomain.com/install.sh | bash

set -e

# 版本信息
PYBOOST_VERSION="1.0.0"

# 定义基础 URL（支持 GitHub Proxy）
if [[ -n "$PYBOOST_MIRROR" ]]; then
    BASE_URL="https://ghproxy.com/https://raw.githubusercontent.com/yinsixuan/pyboost/main"
else
    BASE_URL="https://raw.githubusercontent.com/yinsixuan/pyboost/main"
fi

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# 临时文件目录
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 加载国际化支持
load_locale() {
    local lang=${LANG:-en_US}
    case $lang in
        zh_CN*)
            . <(curl -sSL "$BASE_URL/locales/zh_CN.sh")
            ;;
        ja_JP*)
            . <(curl -sSL "$BASE_URL/locales/ja_JP.sh")
            ;;
        *)
            . <(curl -sSL "$BASE_URL/locales/en_US.sh")
            ;;
    esac
}

# 打印带颜色的信息
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测系统
detect_system() {
    . <(curl -sSL "$BASE_URL/scripts/detector.sh")
}

# 选择镜像源
select_mirror() {
    . <(curl -sSL "$BASE_URL/scripts/mirror.sh")
}

# 安装 Python
install_python() {
    . <(curl -sSL "$BASE_URL/scripts/python.sh")
}

# 配置虚拟环境
setup_venv() {
    . <(curl -sSL "$BASE_URL/scripts/venv.sh")
}

# 主函数
main() {
    # 显示欢迎信息
    clear
    cat << "EOF"
    ____        ____             _   
   |  _ \ _   _| __ )  ___   ___| |_ 
   | |_) | | | |  _ \ / _ \ / __| __|
   |  __/| |_| | |_) | (_) | (__| |_ 
   |_|    \__, |____/ \___/ \___|\__|
          |___/ v1.0.0
EOF

    # 检查 root 权限
    if [[ $EUID -eq 0 ]]; then
        print_warning "$MSG_ROOT_WARNING"
    fi

    # 加载语言包
    load_locale
    print_info "$MSG_INIT"

    # 检测系统
    detect_system
    print_success "$MSG_SYS_DETECTED: $OS $OS_VERSION"

    # 选择镜像源
    select_mirror
    print_success "$MSG_MIRROR_SET"

    # 安装 Python
    install_python
    print_success "$MSG_PYTHON_INSTALLED"

    # 配置虚拟环境
    setup_venv
    print_success "$MSG_VENV_CONFIGURED"

    # 显示完成信息
    cat << EOF

${GREEN}═══════════════════════════════════════════════════════════════${NC}
$MSG_COMPLETE

$MSG_NEXT_STEPS:
  1. $MSG_ACTIVATE_VENV: ${BLUE}source ~/pyenv/venv/bin/activate${NC}
  2. $MSG_INSTALL_PKGS: ${BLUE}pip install -r requirements.txt${NC}
  3. $MSG_CHECK_VERSION: ${BLUE}python --version${NC}

$MSG_DOCS: ${BLUE}https://github.com/yinsixuan/pyboost${NC}
${GREEN}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# 执行主函数
main "$@"
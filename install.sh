#!/usr/bin/env bash
# PyBoost - Python Environment Boost Tool
# Author: Your Name
# Description: One-click Python environment setup tool
# Usage: curl -sSL https://raw.githubusercontent.com/ISHAOHAO/pyboct/main/install.sh | bash

set -e

# 版本信息
PYBOOST_VERSION="1.0.0"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

# 打印带颜色的信息
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测系统
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            OS=$(uname -s)
            OS_VERSION=$(uname -r)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 选择镜像源
select_mirror() {
    echo "选择 PyPI 镜像源："
    echo "1) 清华 (https://pypi.tuna.tsinghua.edu.cn/simple)"
    echo "2) 阿里 (https://mirrors.aliyun.com/pypi/simple)"
    echo "3) 华为 (https://mirrors.huaweicloud.com/repository/pypi/simple)"
    echo "4) 官方 (https://pypi.org/simple)"
    
    read -p "请输入选项编号 [1-4]: " choice
    
    case $choice in
        1) PYPI_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple" ;;
        2) PYPI_MIRROR="https://mirrors.aliyun.com/pypi/simple" ;;
        3) PYPI_MIRROR="https://mirrors.huaweicloud.com/repository/pypi/simple" ;;
        4) PYPI_MIRROR="https://pypi.org/simple" ;;
        *) 
            print_warning "输入无效，使用清华源"
            PYPI_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"
            ;;
    esac
    
    print_success "已选择镜像源: $PYPI_MIRROR"
}

# 配置 pip 镜像
configure_pip() {
    mkdir -p ~/.pip
    
    # 提取域名作为 trusted-host
    TRUSTED_HOST=$(echo $PYPI_MIRROR | awk -F/ '{print $3}')
    
    cat > ~/.pip/pip.conf << EOF
[global]
index-url = $PYPI_MIRROR
trusted-host = $TRUSTED_HOST

[install]
trusted-host = $TRUSTED_HOST
EOF
    
    print_success "pip 镜像源配置完成"
}

# 检查并安装 Python
install_python() {
    if command -v python3 &> /dev/null; then
        PY_VERSION=$(python3 --version 2>&1)
        print_info "检测到 Python: $PY_VERSION"
    else
        print_warning "未检测到 Python，正在安装..."
        
        case $OS in
            ubuntu|debian)
                sudo apt update
                sudo apt install -y python3 python3-pip python3-venv
                ;;
            centos|rhel|fedora)
                sudo yum install -y python3 python3-pip
                ;;
            macos)
                if command -v brew &> /dev/null; then
                    brew install python3
                else
                    print_error "请先安装 Homebrew: https://brew.sh/"
                    exit 1
                fi
                ;;
            *)
                print_error "无法自动安装 Python，请手动安装"
                exit 1
                ;;
        esac
    fi
}

# 创建虚拟环境
create_venv() {
    VENV_PATH="$HOME/pyenv/venv"
    
    if [ ! -d "$VENV_PATH" ]; then
        print_info "创建虚拟环境: $VENV_PATH"
        python3 -m venv "$VENV_PATH"
        
        # 创建激活脚本别名
        echo "alias pyboost='source $VENV_PATH/bin/activate'" >> ~/.bashrc
        if [ -f ~/.zshrc ]; then
            echo "alias pyboost='source $VENV_PATH/bin/activate'" >> ~/.zshrc
        fi
        
        print_success "虚拟环境创建完成"
    else
        print_info "虚拟环境已存在: $VENV_PATH"
    fi
}

# 主函数
main() {
    # 显示欢迎信息
    clear 2>/dev/null || true
    cat << "EOF"
    ____        ____             _   
   |  _ \ _   _| __ )  ___   ___| |_ 
   | |_) | | | |  _ \ / _ \ / __| __|
   |  __/| |_| | |_) | (_) | (__| |_ 
   |_|    \__, |____/ \___/ \___|\__|
          |___/ v1.0.0
EOF

    # 检查是否是 PYBOOST_MIRROR=true 模式
    if [ "$PYBOOST_MIRROR" = "true" ]; then
        print_info "使用镜像加速模式"
    fi

    # 检测系统
    detect_system
    print_info "检测到系统: $OS $OS_VERSION"

    # 选择镜像源
    select_mirror

    # 配置 pip
    configure_pip

    # 安装 Python
    install_python

    # 创建虚拟环境
    create_venv

    # 显示完成信息
    cat << EOF

${GREEN}═══════════════════════════════════════════════════════════════${NC}
✨ PyBoost 安装完成！

当前配置：
  镜像源: $PYPI_MIRROR
  虚拟环境: $HOME/pyenv/venv

下一步操作:
  1. 激活虚拟环境: ${BLUE}source ~/pyenv/venv/bin/activate${NC}
     或使用别名: ${BLUE}pyboost${NC}
  2. 安装依赖包: ${BLUE}pip install -r requirements.txt${NC}
  3. 验证版本: ${BLUE}python --version${NC}

文档地址: ${BLUE}https://github.com/ISHAOHAO/pyboct${NC}
${GREEN}═══════════════════════════════════════════════════════════════${NC}
EOF
}

# 执行主函数
main "$@"
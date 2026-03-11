#!/usr/bin/env bash
# Python 安装模块

install_python() {
    local python_version=${1:-"3.9.0"}
    
    # 检查是否已安装
    if command -v python3 &> /dev/null; then
        local current_version=$(python3 --version 2>&1 | awk '{print $2}')
        print_info "$MSG_PYTHON_EXISTS: $current_version"
        
        read -p "$MSG_UPGRADE_PYTHON [y/N]: " upgrade
        if [[ ! "$upgrade" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    # 安装依赖
    install_dependencies

    # 使用 pyenv 或系统包管理器安装
    if [[ "$USE_PYENV" == "true" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        install_python_with_pyenv "$python_version"
    else
        install_python_with_system "$python_version"
    fi
}

install_dependencies() {
    print_info "$MSG_INSTALLING_DEPENDS"
    
    # 编译依赖
    local deps=()
    case $OS in
        ubuntu|debian)
            deps=("build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" 
                  "libreadline-dev" "libsqlite3-dev" "wget" "curl" "llvm" 
                  "libncurses5-dev" "xz-utils" "tk-dev" "libxml2-dev" 
                  "libxmlsec1-dev" "libffi-dev" "liblzma-dev")
            ;;
        centos|rhel|fedora)
            deps=("gcc" "gcc-c++" "make" "openssl-devel" "bzip2-devel" 
                  "libffi-devel" "zlib-devel" "readline-devel" "sqlite-devel")
            ;;
        macos)
            deps=("openssl" "readline" "sqlite3" "xz" "zlib")
            ;;
    esac
    
    # 批量安装依赖
    for dep in "${deps[@]}"; do
        $PKG_INSTALL "$dep" || print_warning "Failed to install $dep"
    done
}

install_python_with_pyenv() {
    local version=$1
    
    # 安装 pyenv
    if ! command -v pyenv &> /dev/null; then
        print_info "$MSG_INSTALLING_PYENV"
        curl -sSL https://pyenv.run | bash
        
        # 配置环境变量
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
    fi
    
    # 安装指定版本 Python
    print_info "$MSG_INSTALLING_PYTHON $version"
    pyenv install -s "$version"
    pyenv global "$version"
}

install_python_with_system() {
    local version=$1
    
    case $OS in
        ubuntu|debian)
            # 添加 deadsnakes PPA
            if [[ "$OS" == "ubuntu" ]]; then
                add-apt-repository -y ppa:deadsnakes/ppa
                apt update
            fi
            $PKG_INSTALL "python${version%.*}" "python${version%.*}-venv" "python${version%.*}-dev"
            ;;
        centos|rhel)
            # 启用 EPEL 和 SCL
            $PKG_INSTALL epel-release centos-release-scl
            $PKG_INSTALL rh-python${version%.*}
            ;;
        *)
            $PKG_INSTALL python3 python3-pip python3-venv
            ;;
    esac
}
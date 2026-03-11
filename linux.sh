#!/bin/bash
# Python 环境一键初始化脚本 (Linux版)
# 版本: 1.0
# 适用系统: Ubuntu/Debian/CentOS/RHEL/Arch Linux
# 功能: 安装Python/pip/venv, 配置pip国内镜像, 安装常用开发工具

set -e  # 遇到错误退出

# -------------------- 配置区 --------------------
MIRROR_NAMES=("清华源" "阿里源" "腾讯源" "中科大源" "官方源")
MIRROR_URLS=(
    "https://pypi.tuna.tsinghua.edu.cn/simple"
    "https://mirrors.aliyun.com/pypi/simple"
    "https://mirrors.cloud.tencent.com/pypi/simple"
    "https://pypi.mirrors.ustc.edu.cn/simple"
    "https://pypi.org/simple"
)
BACKUP_DIR="/tmp/python-init-backup-$(date +%s)"
LOG_FILE="/tmp/python-init-$(date +%Y%m%d-%H%M%S).log"
PIP_CONFIG_USER="${HOME}/.config/pip/pip.conf"
PIP_CONFIG_SYSTEM="/etc/pip.conf"

# -------------------- 颜色定义 --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -------------------- 辅助函数 --------------------
log() {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $*${NC}" >&2
    exit 1
}

warn() {
    log "${YELLOW}WARNING: $*${NC}"
}

info() {
    log "${GREEN}INFO: $*${NC}"
}

confirm() {
    read -p "$1 [y/N]: " -r
    [[ $REPLY =~ ^[Yy]$ ]]
}

# 检查命令是否存在
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 root 权限
check_root() {
    if [[ $EUID -eq 0 ]]; then
        IS_ROOT=true
    else
        IS_ROOT=false
        if check_command sudo; then
            info "检测到 sudo 可用"
        else
            warn "当前不是 root 且 sudo 不可用，部分操作可能需要手动输入密码或失败"
        fi
    fi
}

# -------------------- 备份与回滚 --------------------
backup_config() {
    mkdir -p "$BACKUP_DIR"
    # 备份 pip 用户配置文件
    if [[ -f "$PIP_CONFIG_USER" ]]; then
        cp "$PIP_CONFIG_USER" "$BACKUP_DIR/pip.user.conf.bak"
        info "已备份用户 pip 配置: $PIP_CONFIG_USER"
    fi
    # 备份 pip 系统配置文件
    if [[ -f "$PIP_CONFIG_SYSTEM" ]]; then
        cp "$PIP_CONFIG_SYSTEM" "$BACKUP_DIR/pip.system.conf.bak"
        info "已备份系统 pip 配置: $PIP_CONFIG_SYSTEM"
    fi
    # 可以备份其他文件（如 .bashrc 等，暂不处理）
}

rollback() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        warn "没有找到备份目录，无法回滚"
        return
    fi
    # 恢复 pip 配置
    if [[ -f "$BACKUP_DIR/pip.user.conf.bak" ]]; then
        cp "$BACKUP_DIR/pip.user.conf.bak" "$PIP_CONFIG_USER"
        info "已恢复用户 pip 配置"
    else
        # 如果没有备份，但当前文件存在，可能脚本之前没有备份过，询问是否删除？
        if [[ -f "$PIP_CONFIG_USER" ]]; then
            warn "用户 pip 配置文件存在但无备份，是否删除？(谨慎)"
            if confirm "删除 $PIP_CONFIG_USER？"; then
                rm -f "$PIP_CONFIG_USER"
                info "已删除 $PIP_CONFIG_USER"
            fi
        fi
    fi
    if [[ -f "$BACKUP_DIR/pip.system.conf.bak" ]]; then
        cp "$BACKUP_DIR/pip.system.conf.bak" "$PIP_CONFIG_SYSTEM"
        info "已恢复系统 pip 配置"
    fi
    # 删除可能由脚本安装的工具（可选，不强制）
    info "回滚完成。注意：脚本安装的 Python 包未自动卸载，如需清理请手动执行。"
}

# -------------------- 系统检测 --------------------
detect_system() {
    info "开始检测系统信息..."
    # 获取发行版 ID 和版本
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
    else
        error "无法识别系统，缺少 /etc/os-release"
    fi

    case $OS_ID in
        ubuntu|debian)
            PKG_MANAGER="apt"
            INSTALL_CMD="apt install -y"
            PYTHON_PACKAGES="python3 python3-pip python3-venv"
            ;;
        centos|rhel|rocky|almalinux)
            if check_command dnf; then
                PKG_MANAGER="dnf"
                INSTALL_CMD="dnf install -y"
            else
                PKG_MANAGER="yum"
                INSTALL_CMD="yum install -y"
            fi
            # CentOS 可能需要 EPEL
            PYTHON_PACKAGES="python3 python3-pip"
            # 注意：python3-venv 在 EPEL 中可能叫 python3-virtualenv？实际 python3 自带 venv 模块，无需额外包
            ;;
        arch)
            PKG_MANAGER="pacman"
            INSTALL_CMD="pacman -S --noconfirm"
            PYTHON_PACKAGES="python python-pip"
            ;;
        *)
            error "不支持的发行版: $OS_ID"
            ;;
    esac
    info "系统: $OS_NAME $OS_VERSION"
    info "包管理器: $PKG_MANAGER"
}

# -------------------- Python 检测 --------------------
check_python() {
    info "检测 Python 环境..."
    if check_command python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        info "Python 已安装，版本: $PYTHON_VERSION"
    else
        warn "Python3 未安装"
        PYTHON_INSTALLED=false
    fi

    if check_command pip3; then
        PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $2}')
        info "pip3 已安装，版本: $PIP_VERSION"
    else
        warn "pip3 未安装"
        PIP_INSTALLED=false
    fi

    # 检查 venv 模块
    if python3 -m venv -h >/dev/null 2>&1; then
        VENV_AVAILABLE=true
        info "venv 模块可用"
    else
        VENV_AVAILABLE=false
        warn "venv 模块不可用"
    fi

    # 如果 Python 未安装，设置标志
    if [[ -z "$PYTHON_INSTALLED" ]]; then
        PYTHON_INSTALLED=true
    fi
}

# -------------------- 安装 Python --------------------
install_python() {
    info "开始安装 Python 环境..."
    if [[ "$PYTHON_INSTALLED" == true ]] && [[ "$PIP_INSTALLED" == true ]] && [[ "$VENV_AVAILABLE" == true ]]; then
        info "Python 环境已完整安装，跳过"
        return
    fi

    case $PKG_MANAGER in
        apt)
            sudo apt update
            sudo $INSTALL_CMD $PYTHON_PACKAGES
            ;;
        yum|dnf)
            # CentOS 可能需要先安装 epel-release
            if [[ $OS_ID == centos || $OS_ID == rhel ]]; then
                if ! rpm -q epel-release >/dev/null 2>&1; then
                    info "安装 EPEL 仓库..."
                    sudo $INSTALL_CMD epel-release
                fi
            fi
            sudo $INSTALL_CMD $PYTHON_PACKAGES
            # 确保 pip 和 venv 可用
            if ! check_command pip3; then
                # 有时 pip3 未链接，尝试安装 python3-pip
                sudo $INSTALL_CMD python3-pip
            fi
            # 对于 CentOS 8+，venv 可能已包含在 python3 中，无需额外安装
            ;;
        pacman)
            sudo $INSTALL_CMD $PYTHON_PACKAGES
            ;;
    esac

    # 再次检测
    check_python
    if [[ "$PYTHON_INSTALLED" != true ]] || [[ "$PIP_INSTALLED" != true ]]; then
        error "Python 安装失败，请检查日志"
    fi
    info "Python 环境安装完成"
}

# -------------------- 配置 pip 镜像 --------------------
configure_pip_mirror() {
    local choice
    local mirror_name
    local mirror_url
    local config_dir
    local config_file
    local target

    # 选择配置范围：用户级还是系统级
    echo ""
    info "选择 pip 配置范围:"
    echo "1) 当前用户 (${PIP_CONFIG_USER})"
    echo "2) 系统全局 (${PIP_CONFIG_SYSTEM})"
    read -p "请输入选择 [1]: " scope_choice
    scope_choice=${scope_choice:-1}

    if [[ $scope_choice == 1 ]]; then
        config_file="$PIP_CONFIG_USER"
        config_dir="$(dirname "$config_file")"
        target="用户"
    elif [[ $scope_choice == 2 ]]; then
        config_file="$PIP_CONFIG_SYSTEM"
        config_dir="$(dirname "$config_file")"
        target="系统"
        # 如果非 root，尝试使用 sudo
        if [[ ! -w "$config_dir" ]] && [[ "$IS_ROOT" != true ]]; then
            if check_command sudo; then
                USE_SUDO=true
            else
                error "需要 root 权限才能写入系统配置，且 sudo 不可用"
            fi
        fi
    else
        warn "无效选择，将使用用户配置"
        config_file="$PIP_CONFIG_USER"
        config_dir="$(dirname "$config_file")"
        target="用户"
    fi

    # 选择镜像
    echo ""
    info "选择 pip 镜像源:"
    for i in "${!MIRROR_NAMES[@]}"; do
        echo "$((i+1))) ${MIRROR_NAMES[$i]} - ${MIRROR_URLS[$i]}"
    done
    read -p "请输入序号 [1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    if [[ $mirror_choice -lt 1 || $mirror_choice -gt ${#MIRROR_NAMES[@]} ]]; then
        error "无效选择"
    fi
    index=$((mirror_choice-1))
    mirror_name="${MIRROR_NAMES[$index]}"
    mirror_url="${MIRROR_URLS[$index]}"

    # 备份现有配置（在 backup_config 中已整体备份，这里不再单独备份）
    # 确保目录存在
    if [[ ! -d "$config_dir" ]]; then
        if [[ "$USE_SUDO" == true ]]; then
            sudo mkdir -p "$config_dir"
        else
            mkdir -p "$config_dir"
        fi
    fi

    # 生成 pip 配置内容
    config_content="[global]
index-url = $mirror_url
trusted-host = $(echo $mirror_url | awk -F/ '{print $3}')

[install]
trusted-host = $(echo $mirror_url | awk -F/ '{print $3}')
"

    # 写入文件
    if [[ "$USE_SUDO" == true ]]; then
        echo "$config_content" | sudo tee "$config_file" >/dev/null
    else
        echo "$config_content" > "$config_file"
    fi

    info "已为 $target 配置 pip 镜像源: $mirror_name"
    # 验证
    pip3 config list 2>/dev/null | grep -q "$mirror_url" && info "验证成功" || warn "验证失败，请检查配置文件"
}

# -------------------- 确保 venv 可用 --------------------
setup_venv() {
    info "检查虚拟环境支持..."
    if [[ "$VENV_AVAILABLE" != true ]]; then
        warn "venv 模块不可用，尝试安装 python3-venv"
        case $PKG_MANAGER in
            apt)
                sudo $INSTALL_CMD python3-venv
                ;;
            yum|dnf)
                # CentOS 可能需要 python3-virtualenv，但 venv 通常内置，先尝试安装
                sudo $INSTALL_CMD python3-virtualenv  # 有时提供 venv
                ;;
            pacman)
                # Arch 的 python 包已包含 venv
                warn "Arch 请确保 python 包完整，尝试重新安装"
                sudo $INSTALL_CMD python
                ;;
        esac
        # 再次检查
        if python3 -m venv -h >/dev/null 2>&1; then
            VENV_AVAILABLE=true
            info "venv 模块已安装"
        else
            error "无法安装 venv 模块，请手动处理"
        fi
    else
        info "venv 模块已可用"
    fi

    # 测试创建虚拟环境
    local test_venv="/tmp/test-venv-$$"
    if python3 -m venv "$test_venv" >/dev/null 2>&1; then
        rm -rf "$test_venv"
        info "虚拟环境创建测试通过"
    else
        error "虚拟环境创建测试失败，请检查权限或磁盘空间"
    fi
}

# -------------------- 安装开发工具 --------------------
install_tools() {
    local mode="$1"  # "menu", "all", "none"
    local tools=("virtualenv" "pipx" "poetry" "ipython")
    local to_install=()

    if [[ "$mode" == "menu" || -z "$mode" ]]; then
        echo ""
        info "选择要安装的 Python 开发工具 (多选，空格分隔，输入 0 跳过):"
        for i in "${!tools[@]}"; do
            echo "$((i+1))) ${tools[$i]}"
        done
        read -p "请输入序号 (例如: 1 2 3): " -a choices
        if [[ ${#choices[@]} -eq 0 || ${choices[0]} == 0 ]]; then
            info "跳过工具安装"
            return
        fi
        for c in "${choices[@]}"; do
            if [[ $c -ge 1 && $c -le ${#tools[@]} ]]; then
                to_install+=("${tools[$((c-1))]}")
            else
                warn "忽略无效序号: $c"
            fi
        done
    elif [[ "$mode" == "all" ]]; then
        to_install=("${tools[@]}")
    else
        return
    fi

    if [[ ${#to_install[@]} -eq 0 ]]; then
        info "没有选择任何工具"
        return
    fi

    info "开始安装: ${to_install[*]}"
    for tool in "${to_install[@]}"; do
        if pip3 show "$tool" >/dev/null 2>&1; then
            info "$tool 已安装，跳过"
        else
            info "正在安装 $tool ..."
            pip3 install --user "$tool" || warn "$tool 安装失败"
        fi
    done
    info "工具安装完成"
    # 提示用户添加 ~/.local/bin 到 PATH
    if [[ " ${to_install[@]} " =~ "pipx" ]] || [[ " ${to_install[@]} " =~ "poetry" ]]; then
        echo -e "${YELLOW}提示: 某些工具的可执行文件在 ~/.local/bin 目录，请确保该目录已在 PATH 中。${NC}"
        echo "可执行: export PATH=\$PATH:~/.local/bin"
    fi
}

# -------------------- 显示菜单 --------------------
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}   Python 环境一键初始化脚本 (Linux)  ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "当前系统: ${BLUE}$OS_NAME $OS_VERSION${NC}"
    echo -e "Python 版本: ${BLUE}${PYTHON_VERSION:-未安装}${NC}"
    echo -e "pip 版本: ${BLUE}${PIP_VERSION:-未安装}${NC}"
    echo -e "venv 模块: ${BLUE}${VENV_AVAILABLE:-未知}${NC}"
    echo ""
    echo "1) 安装/更新 Python 环境"
    echo "2) 配置 pip 镜像源"
    echo "3) 确保虚拟环境支持"
    echo "4) 安装 Python 开发工具"
    echo "5) 一键全部配置 (推荐)"
    echo "0) 退出"
    echo ""
}

# -------------------- 参数解析 --------------------
parse_args() {
    NON_INTERACTIVE=false
    ROLLBACK=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                NON_INTERACTIVE=true
                ;;
            --rollback)
                ROLLBACK=true
                ;;
            --pip-mirror)
                # 快速设置镜像，需要参数 镜像序号或名称
                shift
                if [[ -z "$1" ]]; then
                    error "缺少镜像参数"
                fi
                # 这里简化，只设置清华源，或者根据传入名称匹配
                # 直接调用 configure_pip_mirror 函数，但需要交互？不适合，我们快速设置默认源
                # 为了简单，在非交互模式中不处理该参数，或者直接设置默认源
                warn "--pip-mirror 参数在快速模式下暂不支持，请使用交互菜单或 -y 静默模式"
                exit 1
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  -y, --yes       静默模式，执行默认操作（安装Python+换清华源+venv）"
                echo "  --rollback      回滚上次配置"
                echo "  -h, --help      显示帮助"
                exit 0
                ;;
            *)
                error "未知参数: $1"
                ;;
        esac
        shift
    done
}

# -------------------- 主流程 --------------------
main() {
    parse_args "$@"

    # 检查系统
    detect_system
    check_root
    check_python

    if [[ "$ROLLBACK" == true ]]; then
        rollback
        exit 0
    fi

    if [[ "$NON_INTERACTIVE" == true ]]; then
        # 静默模式：安装Python、配置清华源、确保venv
        info "静默模式开始执行..."
        backup_config
        install_python
        # 配置用户级清华源
        config_file="$PIP_CONFIG_USER"
        config_dir="$(dirname "$config_file")"
        mkdir -p "$config_dir"
        cat > "$config_file" <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn

[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
        info "已配置清华源为默认镜像"
        setup_venv
        # 不安装工具
        info "静默模式执行完成。"
    else
        # 交互模式
        backup_config  # 预先备份
        while true; do
            show_menu
            read -p "请选择操作 [0-5]: " choice
            case $choice in
                1) install_python ;;
                2) configure_pip_mirror ;;
                3) setup_venv ;;
                4) install_tools "menu" ;;
                5)
                    info "开始一键全部配置..."
                    install_python
                    configure_pip_mirror  # 会再次交互选择源，可能不符合一键预期，可改进
                    setup_venv
                    install_tools "menu"
                    info "一键配置完成。"
                    ;;
                0)
                    info "退出脚本"
                    exit 0
                    ;;
                *)
                    warn "无效选择，请重新输入"
                    sleep 1
                    ;;
            esac
            echo ""
            read -p "按回车键继续..."
        done
    fi
}

# 启动
main "$@"
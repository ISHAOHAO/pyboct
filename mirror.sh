#!/usr/bin/env bash
# 镜像源配置模块

# 可用镜像源列表
declare -A MIRRORS=(
    ["清华"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["阿里"]="https://mirrors.aliyun.com/pypi/simple"
    ["华为"]="https://mirrors.huaweicloud.com/repository/pypi/simple"
    ["腾讯"]="https://mirrors.cloud.tencent.com/pypi/simple"
    ["中科大"]="https://pypi.mirrors.ustc.edu.cn/simple"
    ["官方"]="https://pypi.org/simple"
)

# 系统软件源配置
declare -A SYSTEM_MIRRORS=(
    ["ubuntu-清华"]="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/"
    ["ubuntu-阿里"]="https://mirrors.aliyun.com/ubuntu/"
    ["debian-清华"]="https://mirrors.tuna.tsinghua.edu.cn/debian/"
    ["debian-阿里"]="https://mirrors.aliyun.com/debian/"
    ["centos-清华"]="https://mirrors.tuna.tsinghua.edu.cn/centos/"
    ["centos-阿里"]="https://mirrors.aliyun.com/centos/"
)

select_mirror() {
    echo "$MSG_SELECT_MIRROR:"
    
    # 自动测速选择最快镜像
    if [[ "$1" == "--auto" ]] || [[ "$1" == "-a" ]]; then
        select_fastest_mirror
        return
    fi

    # 交互式选择
    PS3="$MSG_CHOOSE_MIRROR: "
    select mirror in "${!MIRRORS[@]}" "$MSG_CUSTOM"; do
        if [[ -n "$mirror" ]]; then
            if [[ "$mirror" == "$MSG_CUSTOM" ]]; then
                read -p "$MSG_ENTER_MIRROR_URL: " custom_url
                PYPI_MIRROR=$custom_url
            else
                PYPI_MIRROR=${MIRRORS[$mirror]}
            fi
            break
        fi
    done
}

select_fastest_mirror() {
    print_info "$MSG_TESTING_MIRRORS"
    
    local fastest=""
    local fastest_time=999999
    
    for name in "${!MIRRORS[@]}"; do
        url=${MIRRORS[$name]}
        start_time=$(date +%s%N)
        
        # 测试连接速度
        if curl -s --connect-timeout 3 -I "$url" >/dev/null 2>&1; then
            end_time=$(date +%s%N)
            elapsed=$(( ($end_time - $start_time) / 1000000 ))
            
            if [[ $elapsed -lt $fastest_time ]]; then
                fastest_time=$elapsed
                fastest=$name
                PYPI_MIRROR=$url
            fi
            
            print_info "  $name: ${elapsed}ms"
        else
            print_warning "  $name: $MSG_TIMEOUT"
        fi
    done
    
    if [[ -n "$fastest" ]]; then
        print_success "$MSG_FASTEST_MIRROR: $fastest (${fastest_time}ms)"
    else
        print_warning "$MSG_NO_MIRROR_AVAILABLE"
        PYPI_MIRROR=${MIRRORS["官方"]}
    fi
}

configure_pip_mirror() {
    # 创建 pip 配置目录
    mkdir -p ~/.pip
    
    # 生成 pip 配置文件
    cat > ~/.pip/pip.conf << EOF
[global]
index-url = $PYPI_MIRROR
trusted-host = $(echo $PYPI_MIRROR | awk -F/ '{print $3}')

[install]
trusted-host = $(echo $PYPI_MIRROR | awk -F/ '{print $3}')
EOF

    print_success "$MSG_PIP_CONFIGURED"
}
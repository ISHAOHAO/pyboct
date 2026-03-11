<#
.SYNOPSIS
    Python 环境一键初始化脚本 (Windows版)
.DESCRIPTION
    自动检测Python环境，安装/修复Python，配置pip国内镜像，确保虚拟环境可用，安装常用开发工具。
    支持交互菜单、静默模式、回滚功能。
.NOTES
    版本: 1.0
    作者: HAOHAO
    要求: PowerShell 5.1+ (建议以管理员身份运行以进行系统级配置)
.LINK
    https://python.org
#>

#requires -version 5.1

# -------------------- 配置区 --------------------
$script:MirrorNames = @("清华源", "阿里源", "腾讯源", "中科大源", "官方源")
$script:MirrorUrls = @(
    "https://pypi.tuna.tsinghua.edu.cn/simple"
    "https://mirrors.aliyun.com/pypi/simple"
    "https://mirrors.cloud.tencent.com/pypi/simple"
    "https://pypi.mirrors.ustc.edu.cn/simple"
    "https://pypi.org/simple"
)
$script:BackupDir = Join-Path $env:TEMP "python-init-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$script:LogFile = Join-Path $env:TEMP "python-init-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:PipConfigUser = Join-Path $env:APPDATA "pip\pip.ini"
$script:PipConfigSystem = "$env:ProgramData\pip\pip.ini"
$script:PythonInstallDir = "$env:LOCALAPPDATA\Programs\Python\Python311"  # 默认安装路径（示例）
$script:WingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
$script:ChocoAvailable = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)

# -------------------- 颜色输出函数 --------------------
function Write-ColorInfo($Text) { Write-Host "INFO: $Text" -ForegroundColor Green; Log "INFO: $Text" }
function Write-ColorWarn($Text) { Write-Host "WARN: $Text" -ForegroundColor Yellow; Log "WARN: $Text" }
function Write-ColorError($Text) { Write-Host "ERROR: $Text" -ForegroundColor Red; Log "ERROR: $Text"; exit 1 }
function Log($Text) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Text" | Out-File -FilePath $script:LogFile -Append }

# -------------------- 辅助函数 --------------------
function Confirm-Prompt($Message) {
    $response = Read-Host "$Message [y/N]"
    return $response -eq 'y' -or $response -eq 'Y'
}

function Test-Administrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# -------------------- 检测系统与Python环境 --------------------
function Detect-System {
    Write-ColorInfo "开始检测系统信息..."
    $script:IsAdmin = Test-Administrator
    if ($script:IsAdmin) {
        Write-ColorInfo "以管理员身份运行，可执行系统级配置"
    } else {
        Write-ColorWarn "当前不是管理员，部分操作（如系统级pip配置、全局安装）可能需要提升权限"
    }
    # 检测Windows版本
    $os = Get-WmiObject Win32_OperatingSystem
    $script:OSVersion = "$($os.Caption) $($os.Version)"
    Write-ColorInfo "操作系统: $script:OSVersion"
}

function Detect-Python {
    Write-ColorInfo "检测Python环境..."
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $script:PythonPath = $python.Source
        $script:PythonVersion = & python --version 2>&1 | ForEach-Object { $_ -replace 'Python ', '' }
        Write-ColorInfo "Python 已安装，路径: $script:PythonPath"
        Write-ColorInfo "Python 版本: $script:PythonVersion"
    } else {
        Write-ColorWarn "Python 未安装或不在PATH中"
        $script:PythonPath = $null
    }

    $pip = Get-Command pip -ErrorAction SilentlyContinue
    if ($pip) {
        $script:PipPath = $pip.Source
        $script:PipVersion = & pip --version 2>&1 | ForEach-Object { ($_ -split ' ')[1] }
        Write-ColorInfo "pip 已安装，路径: $script:PipPath"
        Write-ColorInfo "pip 版本: $script:PipVersion"
    } else {
        Write-ColorWarn "pip 未安装或不在PATH中"
        $script:PipPath = $null
    }

    # 检测venv模块
    if ($python) {
        $venvTest = & python -c "import venv" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $script:VenvAvailable = $true
            Write-ColorInfo "venv 模块可用"
        } else {
            $script:VenvAvailable = $false
            Write-ColorWarn "venv 模块不可用"
        }
    } else {
        $script:VenvAvailable = $false
    }
}

# -------------------- 备份配置 --------------------
function Backup-Config {
    New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    if (Test-Path $script:PipConfigUser) {
        Copy-Item $script:PipConfigUser (Join-Path $script:BackupDir "pip.user.ini.bak")
        Write-ColorInfo "已备份用户pip配置: $script:PipConfigUser"
    }
    if (Test-Path $script:PipConfigSystem) {
        Copy-Item $script:PipConfigSystem (Join-Path $script:BackupDir "pip.system.ini.bak")
        Write-ColorInfo "已备份系统pip配置: $script:PipConfigSystem"
    }
    # 备份PATH？不直接备份，但会记录修改
}

# -------------------- 回滚配置 --------------------
function Rollback-Config {
    if (-not (Test-Path $script:BackupDir)) {
        Write-ColorWarn "没有找到备份目录，无法回滚"
        return
    }
    $userBackup = Join-Path $script:BackupDir "pip.user.ini.bak"
    if (Test-Path $userBackup) {
        Copy-Item $userBackup $script:PipConfigUser -Force
        Write-ColorInfo "已恢复用户pip配置"
    } elseif (Test-Path $script:PipConfigUser) {
        if (Confirm-Prompt "用户pip配置文件存在但无备份，是否删除？") {
            Remove-Item $script:PipConfigUser -Force
            Write-ColorInfo "已删除用户pip配置"
        }
    }
    $sysBackup = Join-Path $script:BackupDir "pip.system.ini.bak"
    if (Test-Path $sysBackup) {
        if ($script:IsAdmin) {
            Copy-Item $sysBackup $script:PipConfigSystem -Force
            Write-ColorInfo "已恢复系统pip配置"
        } else {
            Write-ColorWarn "需要管理员权限才能恢复系统pip配置，请以管理员身份运行"
        }
    } elseif (Test-Path $script:PipConfigSystem -and (Confirm-Prompt "系统pip配置文件存在但无备份，是否删除？")) {
        if ($script:IsAdmin) {
            Remove-Item $script:PipConfigSystem -Force
            Write-ColorInfo "已删除系统pip配置"
        } else {
            Write-ColorWarn "需要管理员权限才能删除系统pip配置"
        }
    }
    Write-ColorInfo "回滚完成。注意：已安装的Python包未自动卸载。"
}

# -------------------- 安装/修复Python --------------------
function Install-Python {
    Write-ColorInfo "开始安装/修复Python..."
    if ($script:PythonPath -and $script:PipPath -and $script:VenvAvailable) {
        Write-ColorInfo "Python环境已完整，跳过安装"
        return
    }

    # 首先尝试使用包管理器安装 (winget 或 choco)
    $installed = $false
    if ($script:WingetAvailable) {
        Write-ColorInfo "尝试使用 winget 安装 Python 3.11"
        winget install Python.Python.3.11 --silent --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-ColorInfo "winget 安装成功"
            $installed = $true
        } else {
            Write-ColorWarn "winget 安装失败，尝试备用方案"
        }
    }
    if (-not $installed -and $script:ChocoAvailable) {
        Write-ColorInfo "尝试使用 Chocolatey 安装 python"
        choco install python -y
        if ($LASTEXITCODE -eq 0) {
            Write-ColorInfo "Chocolatey 安装成功"
            $installed = $true
        } else {
            Write-ColorWarn "Chocolatey 安装失败"
        }
    }

    if (-not $installed) {
        # 降级方案：从官网下载安装包（静默安装）
        Write-ColorInfo "从官网下载 Python 3.11.9 安装包..."
        $installer = "$env:TEMP\python-3.11.9-amd64.exe"
        $url = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
        try {
            Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        } catch {
            Write-ColorError "下载安装包失败: $_"
        }
        Write-ColorInfo "静默安装 Python (自动添加PATH)..."
        $args = "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0"
        Start-Process -FilePath $installer -ArgumentList $args -Wait -NoNewWindow
        Remove-Item $installer -Force
        # 等待PATH更新
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-ColorInfo "官网安装完成"
    }

    # 重新检测
    Detect-Python
    if (-not $script:PythonPath) {
        Write-ColorError "Python 安装失败，请手动安装"
    }
    Write-ColorInfo "Python 环境安装/修复完成"
}

# -------------------- 配置 pip 镜像 --------------------
function Set-PipMirror {
    param(
        [string]$Scope = "user",   # user 或 system
        [int]$MirrorIndex = 0
    )

    if ($Scope -eq "system" -and -not $script:IsAdmin) {
        Write-ColorWarn "配置系统级pip需要管理员权限，将使用用户级配置"
        $Scope = "user"
    }

    if ($Scope -eq "system") {
        $configFile = $script:PipConfigSystem
        $configDir = Split-Path $configFile -Parent
        $target = "系统"
    } else {
        $configFile = $script:PipConfigUser
        $configDir = Split-Path $configFile -Parent
        $target = "用户"
    }

    # 如果未指定镜像索引，交互选择
    if ($MirrorIndex -eq 0) {
        Write-Host "`n选择 pip 镜像源:" -ForegroundColor Cyan
        for ($i=0; $i -lt $script:MirrorNames.Count; $i++) {
            Write-Host "$($i+1). $($script:MirrorNames[$i]) - $($script:MirrorUrls[$i])"
        }
        $choice = Read-Host "请输入序号 [1]"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = 1 }
        $index = [int]$choice - 1
        if ($index -lt 0 -or $index -ge $script:MirrorNames.Count) {
            Write-ColorError "无效选择"
        }
    } else {
        $index = $MirrorIndex - 1
    }

    $mirrorName = $script:MirrorNames[$index]
    $mirrorUrl = $script:MirrorUrls[$index]
    $hostname = ($mirrorUrl -split '/')[2]

    $configContent = @"
[global]
index-url = $mirrorUrl
trusted-host = $hostname

[install]
trusted-host = $hostname
"@

    # 创建目录（如果不存在）
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # 备份已在Backup-Config中完成，此处直接覆盖
    $configContent | Out-File -FilePath $configFile -Encoding utf8 -Force
    Write-ColorInfo "已为 $target 配置 pip 镜像源: $mirrorName"
}

# -------------------- 确保 venv 可用 --------------------
function Ensure-Venv {
    Write-ColorInfo "检查虚拟环境支持..."
    if ($script:VenvAvailable) {
        Write-ColorInfo "venv 模块已可用"
    } else {
        Write-ColorWarn "venv 模块不可用，尝试修复"
        # 尝试重新安装 Python 以确保 venv 模块存在（使用 ensurepip 或升级）
        & python -m ensurepip --upgrade
        & python -m pip install --upgrade virtualenv  # 备选，但 venv 应内置
        # 再次检测
        $venvTest = & python -c "import venv" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $script:VenvAvailable = $true
            Write-ColorInfo "venv 模块已修复"
        } else {
            Write-ColorError "无法启用 venv 模块，请考虑重新安装 Python"
        }
    }

    # 测试创建虚拟环境
    $testVenv = Join-Path $env:TEMP "test-venv-$(Get-Random)"
    try {
        & python -m venv $testVenv
        if ($LASTEXITCODE -eq 0) {
            Remove-Item $testVenv -Recurse -Force
            Write-ColorInfo "虚拟环境创建测试通过"
        } else {
            Write-ColorError "虚拟环境创建测试失败"
        }
    } catch {
        Write-ColorError "虚拟环境创建测试异常: $_"
    }
}

# -------------------- 安装开发工具 --------------------
function Install-DevTools {
    param([string]$Mode = "menu")  # menu, all, none

    $tools = @("virtualenv", "pipx", "poetry", "ipython")
    $toInstall = @()

    if ($Mode -eq "menu") {
        Write-Host "`n选择要安装的 Python 开发工具 (多选，空格分隔，输入 0 跳过):" -ForegroundColor Cyan
        for ($i=0; $i -lt $tools.Count; $i++) {
            Write-Host "$($i+1). $($tools[$i])"
        }
        $choices = Read-Host "请输入序号 (例如: 1 2 3)"
        if ([string]::IsNullOrWhiteSpace($choices)) { $choices = "0" }
        $numbers = $choices -split '\s+' | Where-Object { $_ -match '^\d+$' }
        foreach ($num in $numbers) {
            if ($num -eq 0) {
                Write-ColorInfo "跳过工具安装"
                return
            }
            $idx = [int]$num - 1
            if ($idx -ge 0 -and $idx -lt $tools.Count) {
                $toInstall += $tools[$idx]
            } else {
                Write-ColorWarn "忽略无效序号: $num"
            }
        }
    } elseif ($Mode -eq "all") {
        $toInstall = $tools
    } else {
        return
    }

    if ($toInstall.Count -eq 0) {
        Write-ColorInfo "没有选择任何工具"
        return
    }

    Write-ColorInfo "开始安装: $($toInstall -join ', ')"
    foreach ($tool in $toInstall) {
        $installed = & pip show $tool 2>$null
        if ($installed) {
            Write-ColorInfo "$tool 已安装，跳过"
        } else {
            Write-ColorInfo "正在安装 $tool ..."
            & pip install --user $tool
            if ($LASTEXITCODE -eq 0) {
                Write-ColorInfo "$tool 安装成功"
            } else {
                Write-ColorWarn "$tool 安装失败"
            }
        }
    }
    Write-ColorInfo "工具安装完成"
    # 提示用户将 %APPDATA%\Python\Scripts 加入 PATH
    $userScripts = Join-Path $env:APPDATA "Python\Scripts"
    if (Test-Path $userScripts) {
        Write-Host -ForegroundColor Yellow "提示: 某些工具的可执行文件在 $userScripts 目录，请确保该目录已在 PATH 中。"
    }
}

# -------------------- 显示菜单 --------------------
function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Python 环境一键初始化脚本 (Windows)  " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "当前系统: $script:OSVersion"
    Write-Host "Python 路径: $(if ($script:PythonPath) { $script:PythonPath } else { '未安装' })"
    Write-Host "Python 版本: $(if ($script:PythonVersion) { $script:PythonVersion } else { '未知' })"
    Write-Host "pip 版本: $(if ($script:PipVersion) { $script:PipVersion } else { '未知' })"
    Write-Host "venv 模块: $(if ($script:VenvAvailable) { '可用' } else { '不可用' })"
    Write-Host ""
    Write-Host "1) 安装/修复 Python 环境"
    Write-Host "2) 配置 pip 镜像源"
    Write-Host "3) 确保虚拟环境支持"
    Write-Host "4) 安装 Python 开发工具"
    Write-Host "5) 一键全部配置 (推荐)"
    Write-Host "0) 退出"
    Write-Host ""
}

# -------------------- 参数解析 --------------------
$script:NonInteractive = $false
$script:Rollback = $false
$script:PipMirrorOnly = $false
$script:MirrorIndexArg = 0

for ($i=0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-y' { $script:NonInteractive = $true }
        '--yes' { $script:NonInteractive = $true }
        '--rollback' { $script:Rollback = $true }
        '--pip-mirror' {
            $script:PipMirrorOnly = $true
            if ($i+1 -lt $args.Count -and $args[$i+1] -notmatch '^-') {
                $script:MirrorIndexArg = [int]$args[$i+1]
                $i++
            } else {
                $script:MirrorIndexArg = 1  # 默认清华源
            }
        }
        '-h' { 
            Write-Host @"
用法: $($MyInvocation.MyCommand.Name) [选项]
选项:
  -y, --yes       静默模式，执行默认操作（安装Python+换清华源+venv）
  --rollback      回滚上次配置
  --pip-mirror [序号]  快速配置pip镜像（1=清华源，2=阿里源，...，默认1）
  -h, --help      显示帮助
"@
            exit 0
        }
        '--help' { 
            # 同上
            exit 0
        }
        default {
            Write-ColorError "未知参数: $($args[$i])"
        }
    }
}

# -------------------- 主流程 --------------------
function Main {
    # 初始化日志
    Log "=== Python 环境初始化脚本启动 ==="

    if ($script:Rollback) {
        Rollback-Config
        exit 0
    }

    if ($script:PipMirrorOnly) {
        # 仅配置镜像，不执行其他操作
        Detect-System
        Detect-Python
        Backup-Config
        Set-PipMirror -MirrorIndex $script:MirrorIndexArg -Scope "user"  # 默认用户级
        Write-ColorInfo "pip镜像配置完成"
        exit 0
    }

    Detect-System
    Detect-Python

    if ($script:NonInteractive) {
        Write-ColorInfo "静默模式开始执行..."
        Backup-Config
        Install-Python
        Set-PipMirror -MirrorIndex 1 -Scope "user"   # 清华源
        Ensure-Venv
        # 不安装工具
        Write-ColorInfo "静默模式执行完成。"
    } else {
        Backup-Config
        do {
            Show-Menu
            $choice = Read-Host "请选择操作 [0-5]"
            switch ($choice) {
                '1' { Install-Python }
                '2' { Set-PipMirror }
                '3' { Ensure-Venv }
                '4' { Install-DevTools -Mode "menu" }
                '5' {
                    Write-ColorInfo "开始一键全部配置..."
                    Install-Python
                    Set-PipMirror
                    Ensure-Venv
                    Install-DevTools -Mode "menu"
                    Write-ColorInfo "一键配置完成。"
                }
                '0' {
                    Write-ColorInfo "退出脚本"
                    exit 0
                }
                default {
                    Write-ColorWarn "无效选择，请重新输入"
                    Start-Sleep -Seconds 1
                }
            }
            if ($choice -ne '0') {
                Write-Host ""
                Read-Host "按回车键继续..."
            }
        } while ($true)
    }
}

# 启动主流程
Main
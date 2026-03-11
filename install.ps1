#!/usr/bin/env pwsh
# PyBoost for Windows
# 使用: irm https://raw.githubusercontent.com/ISHAOHAO/pyboct/main/install.ps1 | iex

$ErrorActionPreference = "Stop"
$PyBoostVersion = "1.0.0"

# 颜色定义
$Host.UI.RawUI.ForegroundColor = "Green"
Write-Host @"
    ____        ____             _   
   |  _ \ _   _| __ )  ___   ___| |_ 
   | |_) | | | |  _ \ / _ \ / __| __|
   |  __/| |_| | |_) | (_) | (__| |_ 
   |_|    \__, |____/ \___/ \___|\__|
          |___/ v$PyBoostVersion
"@
$Host.UI.RawUI.ForegroundColor = "White"

# 检测 PowerShell 版本
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "错误：需要 PowerShell 3.0 或更高版本" -ForegroundColor Red
    exit 1
}

# 检测管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "警告：建议以管理员身份运行" -ForegroundColor Yellow
}

# 配置镜像源
$mirrors = @{
    "清华" = "https://pypi.tuna.tsinghua.edu.cn/simple"
    "阿里" = "https://mirrors.aliyun.com/pypi/simple"
    "华为" = "https://mirrors.huaweicloud.com/repository/pypi/simple"
    "官方" = "https://pypi.org/simple"
}

Write-Host "`n选择 PyPI 镜像源："
$i = 1
$mirrorNames = @($mirrors.Keys)
foreach ($name in $mirrorNames) {
    Write-Host "$i. $name"
    $i++
}

$choice = Read-Host "请输入选项编号 [1-$($mirrorNames.Count)]"
# 修复数组索引错误
$index = [int]$choice - 1
if ($index -ge 0 -and $index -lt $mirrorNames.Count) {
    $mirrorName = $mirrorNames[$index]
    $pypiMirror = $mirrors[$mirrorName]
    
    Write-Host "已选择: $mirrorName - $pypiMirror" -ForegroundColor Green
} else {
    Write-Host "输入无效，使用清华源" -ForegroundColor Yellow
    $mirrorName = "清华"
    $pypiMirror = $mirrors[$mirrorName]
}

# 配置 pip
$pipDir = "$env:APPDATA\pip"
if (-not (Test-Path $pipDir)) {
    New-Item -ItemType Directory -Path $pipDir -Force | Out-Null
}

$trustedHost = ($pypiMirror -split '/')[2]
@"
[global]
index-url = $pypiMirror
trusted-host = $trustedHost
"@ | Out-File -FilePath "$pipDir\pip.ini" -Encoding UTF8

Write-Host "✅ pip 镜像源配置完成" -ForegroundColor Green

# 检查 Python 安装
try {
    $pythonVersion = & python --version 2>&1
    Write-Host "检测到 Python: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "未检测到 Python，正在安装..." -ForegroundColor Yellow
    
    # 询问是否自动安装
    $autoInstall = Read-Host "是否自动下载并安装 Python? [Y/n]"
    if ($autoInstall -eq "" -or $autoInstall -eq "Y" -or $autoInstall -eq "y") {
        # 下载 Python 安装程序
        Write-Host "正在下载 Python 3.9.0..." -ForegroundColor Yellow
        $pythonUrl = "https://www.python.org/ftp/python/3.9.0/python-3.9.0-amd64.exe"
        $installer = "$env:TEMP\python-installer.exe"
        
        try {
            Invoke-WebRequest -Uri $pythonUrl -OutFile $installer -UseBasicParsing
            
            # 静默安装 Python
            Write-Host "正在安装 Python..." -ForegroundColor Yellow
            $process = Start-Process -FilePath $installer -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "✅ Python 安装完成" -ForegroundColor Green
                
                # 刷新环境变量
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            } else {
                Write-Host "❌ Python 安装失败" -ForegroundColor Red
            }
        } catch {
            Write-Host "下载或安装失败: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "请手动安装 Python 后重试" -ForegroundColor Yellow
        Write-Host "下载地址: https://www.python.org/downloads/" -ForegroundColor Cyan
    }
}

# 创建虚拟环境
$venvPath = "$env:USERPROFILE\pyenv\venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "创建虚拟环境..." -ForegroundColor Yellow
    
    # 检查 Python 是否可用
    try {
        & python --version 2>$null
        & python -m venv $venvPath
        
        if (Test-Path $venvPath) {
            Write-Host "✅ 虚拟环境创建完成" -ForegroundColor Green
            
            # 创建激活脚本
            $activateScript = @"
# PyBoost 虚拟环境激活脚本
`$venvPath = "$venvPath"
& "`$venvPath\Scripts\Activate.ps1"
"@
            $activateScript | Out-File -FilePath "$env:USERPROFILE\pyboost.ps1" -Encoding UTF8
            
            Write-Host "✅ 激活脚本已创建: $env:USERPROFILE\pyboost.ps1" -ForegroundColor Green
        } else {
            Write-Host "❌ 虚拟环境创建失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "无法创建虚拟环境: $_" -ForegroundColor Red
    }
} else {
    Write-Host "虚拟环境已存在: $venvPath" -ForegroundColor Green
}

# 完成信息
Write-Host @"

═══════════════════════════════════════════════════════════════
✨ PyBoost 安装完成！

当前配置：
  镜像源: $mirrorName ($pypiMirror)
  虚拟环境: $venvPath

下一步操作:
  1. 激活虚拟环境: 
     PowerShell: .\$env:USERPROFILE\pyboost.ps1
     CMD: %USERPROFILE%\pyenv\venv\Scripts\activate.bat
  2. 安装依赖包: pip install -r requirements.txt
  3. 验证版本: python --version

文档地址: https://github.com/ISHAOHAO/pyboct
═══════════════════════════════════════════════════════════════
"@ -ForegroundColor Green

# 暂停，让用户看到结果
Read-Host "按回车键退出"
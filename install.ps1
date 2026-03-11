#!/usr/bin/env pwsh
# PyBoost for Windows
# 使用: irm https://raw.githubusercontent.com/yinsixuan/pyboost/main/install.ps1 | iex

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
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "错误：需要 PowerShell 5.0 或更高版本" -ForegroundColor Red
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
    "官方" = "https://pypi.org/simple"
}

Write-Host "`n选择 PyPI 镜像源："
$i = 1
$mirrors.Keys | ForEach-Object {
    Write-Host "$i. $_"
    $i++
}
$choice = Read-Host "请输入选项编号 [1-$($mirrors.Count)]"
$mirrorName = ($mirrors.Keys)[[$choice] - 1]
$pypiMirror = $mirrors[$mirrorName]

# 配置 pip
$pipDir = "$env:APPDATA\pip"
if (-not (Test-Path $pipDir)) {
    New-Item -ItemType Directory -Path $pipDir -Force | Out-Null
}

@"
[global]
index-url = $pypiMirror
trusted-host = $($pypiMirror.Split('/')[2])
"@ | Out-File -FilePath "$pipDir\pip.ini" -Encoding UTF8

Write-Host "✅ pip 镜像源配置完成" -ForegroundColor Green

# 检查 Python 安装
try {
    $pythonVersion = python --version 2>&1
    Write-Host "检测到 Python: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "未检测到 Python，正在安装..." -ForegroundColor Yellow
    
    # 下载 Python 安装程序
    $pythonUrl = "https://www.python.org/ftp/python/3.9.0/python-3.9.0-amd64.exe"
    $installer = "$env:TEMP\python-installer.exe"
    
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installer
    
    # 静默安装 Python
    Start-Process -FilePath $installer -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    
    # 刷新环境变量
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "✅ Python 安装完成" -ForegroundColor Green
}

# 创建虚拟环境
$venvPath = "$env:USERPROFILE\pyenv\venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "创建虚拟环境..." -ForegroundColor Yellow
    python -m venv $venvPath
    
    # 创建激活脚本
    $activateScript = @"
# PyBoost 虚拟环境激活脚本
`$venvPath = "$venvPath"
& "`$venvPath\Scripts\Activate.ps1"
"@
    $activateScript | Out-File -FilePath "$env:USERPROFILE\pyboost.ps1" -Encoding UTF8
    
    Write-Host "✅ 虚拟环境创建完成" -ForegroundColor Green
}

# 完成信息
Write-Host @"

═══════════════════════════════════════════════════════════════
✨ PyBoost 安装完成！

下一步操作:
  1. 激活虚拟环境: .\$env:USERPROFILE\pyboost.ps1
  2. 安装依赖包: pip install -r requirements.txt
  3. 验证版本: python --version

文档地址: https://github.com/yinsixuan/pyboost
═══════════════════════════════════════════════════════════════
"@ -ForegroundColor Green
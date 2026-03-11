# 🐍 pyboct

一键初始化 Python 开发环境，快速获得干净的 Python、快速的 pip、可用的虚拟环境。支持 Linux / macOS / WSL / Windows。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ✨ 特性

- **智能检测**：自动识别操作系统、发行版、包管理器、Python 安装状态，适配 Linux/macOS/WSL/Windows 各种环境。
- **Python 安装**：根据系统自动安装 Python（Linux 通过包管理器，macOS 通过 Homebrew，Windows 通过 winget/Chocolatey/官网静默安装），并自动配置 PATH。
- **pip 换源**：支持清华、阿里、腾讯、中科大、官方源一键切换，可配置用户级或系统级，自动备份原配置。
- **虚拟环境支持**：检测并修复 venv 模块，测试虚拟环境创建，确保可直接 `python -m venv`。
- **开发工具链**：可选安装 virtualenv、pipx、poetry、ipython 等常用工具（通过 `pip install --user`）。
- **安全可靠**：所有配置文件修改前自动备份到 `/tmp` 或 `%TEMP%`，支持一键回滚，详细日志记录。
- **跨平台支持**：覆盖主流 Linux 发行版（Debian/Ubuntu/CentOS/RHEL/Arch）、macOS（Intel/Apple Silicon）、WSL1/2 以及 Windows 7/10/11。
- **交互/静默双模式**：交互式菜单引导操作，也支持 `-y` 静默模式一键完成所有配置。
- **模块化设计**：功能模块独立，易于扩展和维护（Linux 脚本内部函数化，Windows 脚本函数化）。

---

## 📦 快速开始

### Linux / macOS / WSL

#### 一键远程运行

```bash
bash <(curl -sSL https://raw.githubusercontent.com/ISHAOHAO/pyboct/main/linux.sh)
```

如果上述方法被屏蔽（由网络服务提供商/DNS 阻止），请尝试以下镜像方法：

```bash
bash <(curl -sSL https://gitee.com/is-haohao/pyboct/raw/main/linux.sh)
```

#### 本地运行

```bash
git clone https://github.com/ISHAOHAO/pyboct.git
cd pyboct
chmod +x linux.sh
./linux.sh
```

### Windows

> ⚠️ 建议以管理员身份运行 PowerShell（以获得系统级配置权限）

#### 方法一：一键远程运行（PowerShell）

1. 打开`PowerShell`

2. 复制并粘贴下面命令：

    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ISHAOHAO/pyboct/main/windows.ps1'))
    ```

    如果上述方法被屏蔽（由网络服务提供商/DNS 阻止），请尝试以下镜像方法：

    ```bash
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://gitee.com/is-haohao/pyboct/raw/main/windows.ps1'))
    ```

#### 方法二：本地运行

1.先下载下来本项目的代码内容。

2.把复制下面命令，并将`cd`后面的路径换成你下载的路径

  ```powershell
  # 以管理员身份打开 PowerShell
  Set-ExecutionPolicy Bypass -Scope Process -Force
  cd D:\path\to\pyboct
  .\windows.ps1
```

### 使用命令行直接优化（静默模式，自动确认）

#### Linux/macOS

```bash
./linux.sh -y
```

#### Windows

```powershell
.\windows.ps1 -y
```

### 仅配置 pip 镜像（指定镜像源）

```bash
# Linux/macOS: 使用 --pip-mirror 参数（目前仅支持交互菜单，暂未实现快速参数，但可通过菜单选择）
# 如需快速配置，可手动执行配置函数（见脚本内部）

# Windows: 直接指定镜像序号（1=清华源，2=阿里源...）
.\windows.ps1 --pip-mirror 2
```

### 回滚上次配置

```bash
./linux.sh --rollback
```

```powershell
.\windows.ps1 --rollback
```

---

## 🖥️ 支持的操作系统

| 分类         | 发行版 / 系统                                                                 |
|--------------|--------------------------------------------------------------------------------|
| Linux        | Debian 8~13, Ubuntu 14~25, Kali Linux, Linux Mint, Deepin                    |
| Linux        | RHEL 7~10, CentOS 7~8/Stream, Rocky Linux 8~10, AlmaLinux 8~10, Oracle Linux 8~10 |
| Linux        | Arch Linux, Manjaro                                                           |
| macOS        | macOS 10.15+ (Intel/Apple Silicon) 需预装 Homebrew（脚本会自动安装）         |
| WSL          | WSL1 / WSL2（运行 Linux 脚本）                                               |
| Windows      | Windows 7 / 8 / 10 / 11（通过 PowerShell 脚本 `windows.ps1`）                |

---

## 📚 使用说明

### Linux/macOS 交互式菜单

直接运行 `./linux.sh`，将显示如下菜单：

```txt
========================================
   Python 环境一键初始化脚本 (Linux)  
========================================

当前系统: Ubuntu 22.04
Python 版本: 3.10.12
pip 版本: 22.0.2
venv 模块: 可用

1) 安装/更新 Python 环境
2) 配置 pip 镜像源
3) 确保虚拟环境支持
4) 安装 Python 开发工具
5) 一键全部配置 (推荐)
0) 退出

请选择操作 [0-5]:
```

### Windows 交互式菜单

直接运行 `.\windows.ps1`，将显示类似菜单（中英文根据系统区域自动适配）。

### 命令行选项

#### Linux/macOS (`linux.sh`)

```bash
./linux.sh [选项]

选项:
  -y, --yes               静默模式，执行默认操作（安装Python + 配置清华源 + 确保venv）
  --rollback              执行回滚操作
  -h, --help              显示帮助
```

#### Windows (`windows.ps1`)

```powershell
.\windows.ps1 [-yes] [-rollback] [-pip-mirror <序号>] [-help]

参数:
  -yes                     静默模式（默认操作）
  -rollback                回滚配置
  -pip-mirror <序号>       仅配置 pip 镜像（1=清华源，2=阿里源，3=腾讯源，4=中科大源，5=官方源）
  -help                    显示帮助
```

### 示例

```bash
# Linux 静默模式（自动安装 Python、配置清华源、启用 venv）
./linux.sh -y

# Windows 仅配置阿里云 pip 镜像
.\windows.ps1 -pip-mirror 2

# 回滚到上次备份
./linux.sh --rollback
```

---

## 🧩 脚本模块介绍

### Linux 脚本 (`linux.sh`)

- **系统检测** (`detect_system`)：识别发行版、包管理器、权限。
- **Python 检测** (`check_python`)：检查 Python/pip/venv 是否存在及版本。
- **Python 安装** (`install_python`)：使用包管理器安装 python3、pip3、venv。
- **pip 换源** (`configure_pip_mirror`)：交互式选择镜像源，写入用户级或系统级配置，自动备份。
- **虚拟环境支持** (`setup_venv`)：确保 venv 模块可用并测试创建。
- **开发工具安装** (`install_tools`)：可选安装 virtualenv、pipx、poetry、ipython。
- **备份与回滚** (`backup_config`, `rollback`)：备份 pip 配置文件，支持一键恢复。
- **主菜单** (`show_menu`)：交互式菜单引导操作。

### Windows 脚本 (`windows.ps1`)

- **系统检测**：检测 Windows 版本、管理员权限。
- **Python 检测**：检查 Python/pip/venv 状态。
- **Python 安装**：依次尝试 winget、Chocolatey、官网静默安装，自动添加 PATH。
- **pip 换源**：配置用户级或系统级 pip.ini，提供镜像选择。
- **虚拟环境支持**：测试 venv 可用性，必要时修复。
- **开发工具安装**：通过 `pip install --user` 安装可选工具。
- **备份与回滚**：备份 pip 配置，支持回滚。
- **参数解析**：支持静默、回滚、快速镜像配置等参数。

---

## 🔧 开发与贡献

欢迎贡献代码、报告问题或提出建议！

### 开发环境

```bash
git clone https://github.com/ISHAOHAO/pyboct.git
cd pyboct
```

### 贡献指南

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

### 报告问题

如果你在使用中遇到任何问题，欢迎在 [Issues](https://github.com/ISHAOHAO/pyboct/issues) 页面提出，并提供：

- 操作系统版本
- Python 环境信息
- 执行的命令和错误日志（位于 `/tmp/python-init-*.log` 或 `%TEMP%\python-init-*.log`）

---

## 📄 许可证

[MIT](LICENSE) © 2026 pyboct contributors
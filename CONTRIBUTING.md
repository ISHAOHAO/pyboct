# 🤝 贡献指南

感谢你考虑为 **pyboct** 贡献代码！你的帮助将使这个 Python 环境初始化工具变得更好。无论你是报告 bug、提出新功能，还是直接提交代码，我们都非常欢迎。

请花几分钟阅读这份指南，以便你的贡献能顺利被采纳。

---

## 📋 目录

- [报告 Bug](#报告-bug)
- [提出新功能](#提出新功能)
- [提交代码](#提交代码)
  - [开发环境设置](#开发环境设置)
  - [代码规范](#代码规范)
  - [测试](#测试)
  - [提交信息规范](#提交信息规范)
  - [Pull Request 流程](#pull-request-流程)
- [许可证](#许可证)

---

## 🐛 报告 Bug

如果你在使用中遇到了问题，请先确认是否为最新版本，并搜索 [Issues](https://github.com/ISHAOHAO/pyboct/issues) 看是否已被报告过。如果没有，请创建新 Issue，并包含以下信息：

- 操作系统及版本（例如 `Ubuntu 22.04` / `Windows 11`）
- Python 版本（`python3 --version`）和 pip 版本（`pip3 --version`）
- 执行的命令及完整输出（注意隐藏个人敏感信息）
- 如果涉及脚本运行错误，请提供日志文件内容：
  - Linux/macOS: `/tmp/python-init-*.log`
  - Windows: `%TEMP%\python-init-*.log`
- 你期望的行为与实际行为的描述

---

## 💡 提出新功能

如果你有好的想法，欢迎先通过 [Issues](https://github.com/ISHAOHAO/pyboct/issues) 讨论，避免重复劳动。请清晰描述：

- 新功能要解决什么问题
- 可能的实现思路
- 是否愿意自己实现它

---

## 🛠 提交代码

### 开发环境设置

1. **Fork 本仓库** 并克隆到本地：
   ```bash
   git clone https://github.com/你的用户名/pyboct.git
   cd pyboct
   ```

2. **创建新分支**：
   ```bash
   git checkout -b feature/你的功能名
   ```

3. **环境准备**（用于测试）：
   - Linux/macOS: 安装 `bats`（Bash 自动化测试）和 `shellcheck`（Shell 脚本检查）：
     ```bash
     # Debian/Ubuntu
     sudo apt install bats shellcheck
     # CentOS/RHEL
     sudo yum install bats shellcheck
     # macOS (Homebrew)
     brew install bats-core shellcheck
     ```
   - Windows: 安装 `Pester`（PowerShell 测试框架）：
     ```powershell
     Install-Module -Name Pester -Force -SkipPublisherCheck
     ```

### 代码规范

- **Shell 脚本**（`linux.sh` 及库文件）：
  - 遵循 [Google Shell 风格指南](https://google.github.io/styleguide/shellguide.html)
  - 使用 `shellcheck` 进行静态检查，确保无严重警告
  - 函数命名采用小写加下划线（如 `detect_system`）
  - 变量命名清晰，全局变量使用 `readonly` 或大写（如 `BACKUP_DIR`）
  - 添加充分的注释，尤其是复杂逻辑

- **PowerShell 脚本**（`windows.ps1`）：
  - 遵循 [PowerShell 最佳实践](https://learn.microsoft.com/en-us/powershell/scripting/developer/overview)
  - 函数使用帕斯卡命名（如 `Install-Python`）
  - 变量使用小驼峰（如 `$pythonVersion`）
  - 添加基于注释的帮助（`<# ... #>`）
  - 使用 `Write-*` 函数输出信息，而非直接 `Write-Host`（已封装）

- **所有脚本**：
  - 保持跨平台兼容性（注意路径分隔符、换行符等）
  - 对关键操作（如修改配置文件）必须实现备份与回滚
  - 错误处理：遇到致命错误应退出并给出清晰提示

### 测试

- **Linux/macOS**：使用 `bats` 编写测试用例，存放于 `test/` 目录。运行测试：
  ```bash
  bats test/
  ```
  示例测试文件 `test/linux.bats` 应测试各函数的基本行为。

- **Windows**：使用 `Pester` 编写测试，存放于 `test/` 目录（以 `.Tests.ps1` 结尾）。运行测试：
  ```powershell
  Invoke-Pester -Path .\test\
  ```

- **新增功能必须包含测试**，确保现有功能不受影响。

### 提交信息规范

提交信息应清晰描述改动，推荐格式：

```
<类型>(<范围>): <简短描述>

<详细描述>

<尾部（如关闭 Issue）>
```

类型（type）可以是：
- `feat`：新功能
- `fix`：修复 bug
- `docs`：文档更新
- `style`：代码风格调整（不影响功能）
- `refactor`：重构
- `test`：测试相关
- `chore`：构建/工具链变动

示例：
```
feat(linux): 添加对 openSUSE 的支持

- 增加 openSUSE 的包管理器检测（zypper）
- 调整 Python 安装命令
- 添加测试用例

Closes #12
```

### Pull Request 流程

1. **确保你的分支基于最新的 `main` 分支**：
   ```bash
   git remote add upstream https://github.com/ISHAOHAO/pyboct.git
   git fetch upstream
   git rebase upstream/main
   ```

2. **运行所有测试并通过**。

3. **推送分支到你的 Fork**：
   ```bash
   git push origin feature/你的功能名
   ```

4. **在 GitHub 上创建 Pull Request**：
   - 清晰描述改动内容和动机
   - 关联相关的 Issue（如果有）
   - 选择合适的人审阅（可以 @ 维护者）

5. **等待 CI 检查通过**（GitHub Actions 会自动运行测试和 shellcheck）。

6. **根据审阅意见修改**。如果需要更新 PR，请直接推送新 commit 到同一分支，PR 会自动更新。

7. **合并后，你的贡献将出现在项目中！** 🎉

---

## 📜 许可证

通过提交代码，你同意你的贡献将采用与本项目相同的 [MIT 许可证](LICENSE)。

---

再次感谢你的贡献！如有任何问题，欢迎在 [Issues](https://github.com/ISHAOHAO/pyboct/issues) 中提出。
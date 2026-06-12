# env-setup

Windows 开发环境一键初始化脚本。

## 快速开始

```powershell
powershell -ExecutionPolicy Bypass .\bootstrap.ps1
```

## 安装内容

| 工具 | 说明 | 安装方式 |
|------|------|----------|
| [ripgrep](https://github.com/BurntSushi/ripgrep) (rg) | 极速代码搜索 | winget |
| [fd](https://github.com/sharkdp/fd) | 快速文件查找 | winget |
| [jq](https://jqlang.github.io/jq/) | 命令行 JSON 处理 | winget |
| [bat](https://github.com/sharkdp/bat) | 带语法高亮的 cat | winget |
| [pnpm](https://pnpm.io/) | 快速省磁盘的包管理器 | winget |
| [Go](https://go.dev/) | Go 语言 | winget |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 容器化开发环境 | winget |
| [GitHub CLI](https://cli.github.com/) (gh) | GitHub 命令行工具 | winget |

## 配置项

| 参数 | 说明 |
|------|------|
| `-NoDocker` | 跳过 Docker Desktop 安装（约 623MB） |
| `-NoGo` | 跳过 Go 安装 |
| `-NoSsh` | 跳过 SSH 密钥生成 |
| `-DryRun` | 仅预览要安装的内容，不实际安装 |

### 示例

```powershell
# 跳过 Docker（体积太大，后续单独装）
.\bootstrap.ps1 -NoDocker

# 仅预览
.\bootstrap.ps1 -DryRun
```

## 首次使用

脚本运行后还会引导：

1. **SSH 密钥** — 自动生成并提示添加到 GitHub
2. **Git 全局配置** — 设置 user.name / user.email
3. **Go 环境变量** — 自动加入用户 PATH

完成后记得：

```powershell
# 登录 GitHub CLI（需要浏览器授权）
gh auth login

# 手动启动 Docker Desktop
```

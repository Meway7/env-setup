param(
    [switch]$NoDocker,
    [switch]$NoGo,
    [switch]$NoSsh,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$tools = @()

# ---------- 基础工具 ----------
$tools += @(
    @{ id = "BurntSushi.ripgrep";    name = "ripgrep (rg)" }
    @{ id = "sharkdp.fd";            name = "fd" }
    @{ id = "jqlang.jq";             name = "jq" }
    @{ id = "sharkdp.bat";           name = "bat" }
)

# ---------- 包管理器 ----------
$tools += @(
    @{ id = "pnpm.pnpm";             name = "pnpm" }
)

# ---------- GitHub ----------
$tools += @(
    @{ id = "GitHub.cli";           name = "GitHub CLI (gh)" }
)

# ---------- 运行时 ----------
if (-not $NoGo) {
    $tools += @(
        @{ id = "GoLang.Go";         name = "Go" }
    )
}

if (-not $NoDocker) {
    $tools += @(
        @{ id = "Docker.DockerDesktop"; name = "Docker Desktop" }
    )
}

# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows Dev Environment Bootstrap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检查 winget
Write-Host "[1/4] 检查 winget..." -ForegroundColor Yellow
$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Host "  ❌ winget 不可用，请先安装应用安装程序。" -ForegroundColor Red
    Write-Host "     到 https://apps.microsoft.com/store/detail/9NBLGGH4NNS1 安装" -ForegroundColor Red
    exit 1
}
Write-Host "  ✅ winget 可用" -ForegroundColor Green

# 2. 安装工具
Write-Host "[2/4] 安装工具..." -ForegroundColor Yellow
foreach ($t in $tools) {
    if ($DryRun) {
        Write-Host "  [DRY-RUN] winget install --id $($t.id)" -ForegroundColor Gray
        continue
    }
    Write-Host "  正在安装 $($t.name) ..." -NoNewline
    $r = & winget install --id $t.id --accept-source-agreements --accept-package-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  可能已安装或出错" -ForegroundColor Yellow
    }
}

# 3. SSH + Git 配置
Write-Host "[3/4] SSH + Git 配置..." -ForegroundColor Yellow

$sshDir = "$env:USERPROFILE\.ssh"
$keyFile = "$sshDir\id_ed25519"

if (-not $NoSsh -and -not (Test-Path $keyFile)) {
    Write-Host "  生成 SSH 密钥 (ed25519)..." -ForegroundColor Gray
    # 需要用户输入 GitHub 用户名
    $ghUser = Read-Host "  请输入 GitHub 用户名 (留空跳过)"
    if ($ghUser) {
        $ghEmail = Read-Host "  请输入 GitHub 邮箱"
        ssh-keygen -t ed25519 -C "$ghUser@github" -f $keyFile -N "" 2>$null

        # 写入 SSH config
        @"
Host github.com
  HostName github.com
  User git
  IdentityFile $($keyFile -replace '\\', '/')
  IdentitiesOnly yes
"@ | Out-File -FilePath "$sshDir\config" -Encoding ASCII

        Write-Host "  ✅ SSH 密钥已生成: $keyFile.pub" -ForegroundColor Green
        Write-Host "  ⚠️  请手动将以下公钥添加到 GitHub:" -ForegroundColor Yellow
        Write-Host "     https://github.com/settings/ssh/new" -ForegroundColor Yellow
        Write-Host ""
        Get-Content "$keyFile.pub"
        Write-Host ""

        # Git 全局配置
        git config --global user.name $ghUser 2>$null
        git config --global user.email $ghEmail 2>$null
        Write-Host "  ✅ Git 全局配置已设置: $ghUser <$ghEmail>" -ForegroundColor Green
    }
} elseif (Test-Path $keyFile) {
    Write-Host "  ✅ SSH 密钥已存在: $keyFile.pub" -ForegroundColor Green
}

# 4. 后置配置
Write-Host "[4/4] 后置配置..." -ForegroundColor Yellow

# 4a. Go 环境变量 (如果 Go 没被 winget 安装走 ~/sdk/go 路径)
$goRoot = "$env:USERPROFILE\sdk\go"
if (Test-Path "$goRoot\bin\go.exe") {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$goRoot*") {
        $newPath = "$goRoot\bin;" + $userPath
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "  ✅ Go ($goRoot) 已加入用户 PATH" -ForegroundColor Green
    }
}

# 4b. 将 GitHub CLI 加入 PATH
$ghPath = "C:\Program Files\GitHub CLI"
if (Test-Path "$ghPath\gh.exe") {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$ghPath*") {
        $newPath = "$ghPath;" + $userPath
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "  ✅ GitHub CLI 已加入用户 PATH" -ForegroundColor Green
    }
}

# 4c. 验证关键版本
Write-Host "" -NoNewline
Write-Host "-------- 版本验证 --------" -ForegroundColor Cyan
$checks = @(
    @{ cmd = "go";        args = "version" }
    @{ cmd = "node";      args = "--version" }
    @{ cmd = "pnpm";      args = "--version" }
    @{ cmd = "rg";        args = "--version" }
    @{ cmd = "fd";        args = "--version" }
    @{ cmd = "jq";        args = "--version" }
    @{ cmd = "bat";       args = "--version" }
    @{ cmd = "git";       args = "--version" }
)
foreach ($c in $checks) {
    $ver = & $c.cmd $c.args 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $($c.cmd) $($ver.Split()[0])" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $($c.cmd) 未找到" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  完成！记得:" -ForegroundColor Cyan
Write-Host "  1. 新开一个终端让 PATH 生效" -ForegroundColor Cyan
Write-Host "  2. gh auth login 登录 GitHub" -ForegroundColor Cyan
Write-Host "  3. 手动启动 Docker Desktop" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

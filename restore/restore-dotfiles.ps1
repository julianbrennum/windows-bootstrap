#Requires -Version 7
# Installs chezmoi (if missing) and applies dotfiles from the personal chezmoi repo.
# Called by bootstrap.ps1 — can also be run standalone.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The repo is private. Clone over HTTPS with gh as the credential helper: on a
# fresh install there is no ~/.ssh/config or core.sshCommand yet, so Git's
# bundled ssh cannot see the Keeper agent and port 22 to github.com may hang.
# Once chezmoi has written ~/.ssh/config, the remote switches to the ssh alias.
$CHEZMOI_REPO = "https://github.com/julianbrennum/chezmoi.git"
$CHEZMOI_SSH_REMOTE = "github-personal:julianbrennum/chezmoi.git"
$VSCODE_EXTENSIONS = Join-Path $PSScriptRoot "..\dotfiles\vscode-extensions.txt"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# winget installs from this session are not on PATH until it is re-read.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# --- chezmoi ---
Write-Step "Checking chezmoi"
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing chezmoi via winget..."
    winget install --id twpayne.chezmoi --exact --accept-package-agreements --accept-source-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

Write-Step "Signing in to GitHub (julianbrennum)"
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { gh auth login --hostname github.com --git-protocol https --web }
gh auth setup-git

Write-Step "Applying dotfiles ($CHEZMOI_REPO)"
chezmoi init --apply $CHEZMOI_REPO
chezmoi git -- remote set-url origin $CHEZMOI_SSH_REMOTE

# --- VS Code extensions ---
if ((Get-Command code -ErrorAction SilentlyContinue) -and (Test-Path $VSCODE_EXTENSIONS)) {
    Write-Step "Installing VS Code extensions"
    Get-Content $VSCODE_EXTENSIONS | Where-Object { $_ -match '\S' } | ForEach-Object {
        Write-Host "  $_"
        code --install-extension $_ --force 2>&1 | Out-Null
    }
}

Write-Host "Dotfiles restored." -ForegroundColor Green

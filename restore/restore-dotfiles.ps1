#Requires -Version 7
# Installs chezmoi (if missing) and applies dotfiles from the personal chezmoi repo.
# Called by bootstrap.ps1 — can also be run standalone.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CHEZMOI_REPO = "git@github.com:julianbrennum/chezmoi.git"
$VSCODE_EXTENSIONS = Join-Path $PSScriptRoot "..\dotfiles\vscode-extensions.txt"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- chezmoi ---
Write-Step "Checking chezmoi"
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing chezmoi via winget..."
    winget install --id twpayne.chezmoi --exact --accept-package-agreements --accept-source-agreements
}

Write-Step "Applying dotfiles ($CHEZMOI_REPO)"
chezmoi init --apply $CHEZMOI_REPO

# --- VS Code extensions ---
if ((Get-Command code -ErrorAction SilentlyContinue) -and (Test-Path $VSCODE_EXTENSIONS)) {
    Write-Step "Installing VS Code extensions"
    Get-Content $VSCODE_EXTENSIONS | Where-Object { $_ -match '\S' } | ForEach-Object {
        Write-Host "  $_"
        code --install-extension $_ --force 2>&1 | Out-Null
    }
}

Write-Host "Dotfiles restored." -ForegroundColor Green

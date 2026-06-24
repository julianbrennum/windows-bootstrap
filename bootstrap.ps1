#Requires -Version 7
# Fresh-install bootstrap. Run elevated (admin) from the repo root.
# Usage: pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
# Re-running is safe: each step is idempotent.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Done($msg) { Write-Host "    $msg" -ForegroundColor Green }

# --- Ensure running elevated ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script from an elevated PowerShell prompt."
    exit 1
}

$root = $PSScriptRoot

# =========================================================================
# 1. winget — declarative DSC config
# =========================================================================
Write-Step "Installing apps via winget DSC"
winget configure --file (Join-Path $root "packages\winget.dsc.yaml") --accept-configuration-agreements --disable-interactivity
Write-Done "winget DSC applied"

# =========================================================================
# 2. Dotfiles (chezmoi) + VS Code extensions
# =========================================================================
Write-Step "Restoring dotfiles"
& (Join-Path $root "restore\restore-dotfiles.ps1")

Write-Host "`nBootstrap complete." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  - Log in to NetBird: netbird up" -ForegroundColor White
Write-Host "  - Open Keeper and unlock your vault" -ForegroundColor White
Write-Host "  - Sign in to browsers, Spotify, Discord, etc." -ForegroundColor White

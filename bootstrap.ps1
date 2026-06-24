#Requires -Version 7
# Fresh-install bootstrap. Run elevated (admin) from the repo root.
# Usage: pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
# Re-running is safe: each step is idempotent.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Done($msg) { Write-Host "    $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    $msg (skipped)" -ForegroundColor Yellow }

# --- Ensure running elevated ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script from an elevated PowerShell prompt."
    exit 1
}

$root = $PSScriptRoot

# =========================================================================
# 1. winget — declarative DSC config (preferred)
# =========================================================================
Write-Step "Installing apps via winget DSC"
$dscFile = Join-Path $root "packages\winget.dsc.yaml"
if (Test-Path $dscFile) {
    winget configure --file $dscFile --accept-configuration-agreements --disable-interactivity
    Write-Done "winget DSC applied"
} else {
    Write-Skip "packages\winget.dsc.yaml not found"
}

# =========================================================================
# 2. scoop — CLI/dev tools
# =========================================================================
Write-Step "Installing scoop packages"
$scoopExport = Join-Path $root "packages\scoop-export.json"
$scoopApps = (Get-Content $scoopExport -Raw | ConvertFrom-Json).apps
if ($scoopApps.Count -gt 0) {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing scoop..."
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        irm get.scoop.sh | iex
    }
    # Restore buckets first
    $buckets = (Get-Content $scoopExport -Raw | ConvertFrom-Json).buckets
    foreach ($b in $buckets) { scoop bucket add $b.Name $b.Source 2>$null }
    # Install apps
    foreach ($app in $scoopApps) {
        scoop install "$($app.Source)/$($app.Name)" 2>$null
    }
    Write-Done "scoop packages installed"
} else {
    Write-Skip "no scoop apps in manifest"
}

# =========================================================================
# 3. Chocolatey — anything else
# =========================================================================
Write-Step "Installing chocolatey packages"
$chocoConfig = Join-Path $root "packages\choco.config"
$chocoHasPackages = (Select-String -Path $chocoConfig -Pattern '<package ' -Quiet)
if ($chocoHasPackages) {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        irm https://community.chocolatey.org/install.ps1 | iex
    }
    choco install $chocoConfig --yes
    Write-Done "choco packages installed"
} else {
    Write-Skip "no packages in choco.config"
}

# =========================================================================
# 4. Dotfiles (chezmoi) + VS Code extensions
# =========================================================================
Write-Step "Restoring dotfiles"
& (Join-Path $root "restore\restore-dotfiles.ps1")

Write-Host "`nBootstrap complete." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  - Log in to NetBird: netbird up" -ForegroundColor White
Write-Host "  - Open Keeper and unlock your vault" -ForegroundColor White
Write-Host "  - Sign in to browsers, Spotify, Discord, etc." -ForegroundColor White

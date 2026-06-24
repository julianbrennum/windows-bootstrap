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
# 1. winget — base (all machines) + machine-specific manifest
# =========================================================================
Write-Step "Installing apps via winget DSC"

$hostManifests = @{
    '8K-WORKSTATION' = 'packages\winget-desktop.dsc.yaml'
    '4K-Laptop'      = 'packages\winget-laptop.dsc.yaml'
}

$machineManifest = $hostManifests[$env:COMPUTERNAME]
if (-not $machineManifest) {
    Write-Error "No winget manifest mapped for hostname '$($env:COMPUTERNAME)'. Add it to the `$hostManifests table in bootstrap.ps1."
    exit 1
}

Write-Host "  Base manifest..."
winget configure --file (Join-Path $root 'packages\winget-base.dsc.yaml') --accept-configuration-agreements --disable-interactivity

Write-Host "  Machine-specific manifest ($($env:COMPUTERNAME))..."
winget configure --file (Join-Path $root $machineManifest) --accept-configuration-agreements --disable-interactivity

Write-Done "winget DSC applied"

# =========================================================================
# 2. Windows OpenSSH Authentication Agent (required by Keeper SSH Agent)
# =========================================================================
Write-Step "Configuring ssh-agent service"
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service -Name ssh-agent
Write-Done "ssh-agent running (Keeper SSH Agent dependency)"

# =========================================================================
# 3. Dotfiles (chezmoi) + VS Code extensions
# =========================================================================
Write-Step "Restoring dotfiles"
& (Join-Path $root "restore\restore-dotfiles.ps1")

Write-Host "`nBootstrap complete." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  - Log in to NetBird: netbird up" -ForegroundColor White
Write-Host "  - Open Keeper and unlock your vault" -ForegroundColor White
Write-Host "  - Sign in to browsers, Spotify, Discord, etc." -ForegroundColor White

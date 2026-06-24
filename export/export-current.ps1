#Requires -Version 7
# Run on the OLD machine before wiping. Refreshes all manifests from live state, then commits.
# Usage: pwsh -ExecutionPolicy Bypass -File .\export\export-current.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot | Split-Path

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- winget ---
Write-Step "Exporting winget packages"
winget export --output "$root\packages\winget-packages.json" --accept-source-agreements
Write-Host "  winget-packages.json updated"

# --- scoop ---
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Step "Exporting scoop packages"
    scoop export | ConvertFrom-Json | ConvertTo-Json -Depth 10 |
        Set-Content "$root\packages\scoop-export.json" -Encoding UTF8
    Write-Host "  scoop-export.json updated"
} else {
    Write-Host "  scoop not installed, skipping" -ForegroundColor Yellow
}

# --- choco ---
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Step "Exporting chocolatey packages"
    choco export "$root\packages\choco.config" --include-version-numbers
    Write-Host "  choco.config updated"
} else {
    Write-Host "  choco not installed, skipping" -ForegroundColor Yellow
}

# --- VS Code extensions ---
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Step "Exporting VS Code extensions"
    code --list-extensions | Set-Content "$root\dotfiles\vscode-extensions.txt" -Encoding UTF8
    Write-Host "  vscode-extensions.txt updated"
} else {
    Write-Host "  code not in PATH, skipping" -ForegroundColor Yellow
}

# --- Commit & push ---
Write-Step "Committing snapshot"
Set-Location $root
$date = Get-Date -Format 'yyyy-MM-dd'
git add -A
git diff --cached --quiet && Write-Host "Nothing changed, skipping commit" -ForegroundColor Yellow && exit 0
git commit -m "snapshot $date"
git push
Write-Host "Done. Snapshot pushed." -ForegroundColor Green

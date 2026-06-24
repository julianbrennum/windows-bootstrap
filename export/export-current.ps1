#Requires -Version 7
# Run on the OLD machine before wiping. Refreshes manifests from live state, then commits.
# Usage: pwsh -ExecutionPolicy Bypass -File .\export\export-current.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot | Split-Path

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# --- winget (raw snapshot — audit only, bootstrap uses winget.dsc.yaml) ---
Write-Step "Exporting winget packages"
winget export --output "$root\packages\winget-packages.json" --accept-source-agreements
Write-Host "  winget-packages.json updated"

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
if (-not (git diff --cached --quiet)) {
    git commit -m "snapshot $date"
    git push
    Write-Host "Done. Snapshot pushed." -ForegroundColor Green
} else {
    Write-Host "Nothing changed, skipping commit." -ForegroundColor Yellow
}

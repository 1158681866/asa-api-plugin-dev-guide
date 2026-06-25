param(
    [string]$Message = "",
    [string]$Remote = "origin",
    [string]$Branch = "",
    [switch]$NoInstall
)

$ErrorActionPreference = "Stop"

function Run-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

Run-Git rev-parse --is-inside-work-tree | Out-Null

if (-not $Branch) {
    $Branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $Branch) {
        throw "Cannot determine current git branch. Pass -Branch explicitly."
    }
}

if (-not $NoInstall) {
    $installScript = Join-Path $PSScriptRoot "install-skill.ps1"
    if (Test-Path $installScript) {
        & $installScript -Force
    }
}

$status = (& git status --porcelain)
if (-not $status) {
    Write-Host "No local changes to push."
    Run-Git push $Remote $Branch
    exit 0
}

Write-Host "Changes:"
$status | ForEach-Object { Write-Host "  $_" }

if (-not $Message) {
    $Message = "docs: update asa api plugin guide"
}

Run-Git add -A
Run-Git commit -m $Message
Run-Git push $Remote $Branch

Write-Host "Pushed to $Remote/$Branch"

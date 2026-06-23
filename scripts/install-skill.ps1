param(
    [string]$CodexHome = "$env:USERPROFILE\.codex",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$source = Join-Path $repoRoot "skills\asa-api-plugin-dev"
$targetRoot = Join-Path $CodexHome "skills"
$target = Join-Path $targetRoot "asa-api-plugin-dev"

if (-not (Test-Path $source)) {
    throw "Skill source not found: $source"
}

New-Item -ItemType Directory -Force $targetRoot | Out-Null

if (Test-Path $target) {
    if (-not $Force) {
        throw "Skill already exists: $target. Re-run with -Force to overwrite."
    }
    Remove-Item -Recurse -Force $target
}

Copy-Item -Recurse $source $target

Write-Host "Installed skill: $target"
Write-Host "Restart Codex or open a new session if the skill list does not refresh immediately."

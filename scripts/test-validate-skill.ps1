$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "ASSERTION FAILED: $Message"
    }
}

$validator = Join-Path $PSScriptRoot 'validate-skill.ps1'
$source = [IO.Path]::GetFullPath((Join-Path (Join-Path $PSScriptRoot '..') 'skills\asa-api-plugin-dev'))
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("asa-skill-validator-test-" + [guid]::NewGuid().ToString('N'))
$copy = Join-Path $testRoot 'asa-api-plugin-dev'
$wrongCaseCopy = Join-Path $testRoot 'ASA-API-PLUGIN-DEV'

try {
    Copy-Item -LiteralPath $source -Destination $copy -Recurse
    & $validator -SkillPath $copy

    Copy-Item -LiteralPath $source -Destination $wrongCaseCopy -Recurse
    $caseFailed = $false
    try {
        & $validator -SkillPath $wrongCaseCopy
    }
    catch {
        $caseFailed = $_.Exception.Message -like "Skill folder 'ASA-API-PLUGIN-DEV' must match frontmatter name*"
    }
    Assert-True $caseFailed 'Skill folder casing must exactly match the frontmatter name'

    $missingReference = Join-Path $copy 'references\api-lookup.md'
    Remove-Item -LiteralPath $missingReference -Force
    $missingFailed = $false
    try {
        & $validator -SkillPath $copy
    }
    catch {
        $missingFailed = $_.Exception.Message -like 'Missing Skill references:*'
    }
    Assert-True $missingFailed 'missing Markdown-linked reference must fail validation'

    Copy-Item -LiteralPath (Join-Path $source 'references\api-lookup.md') -Destination $missingReference
    $orphanReference = Join-Path $copy 'references\orphan.md'
    Set-Content -LiteralPath $orphanReference -Value '# Orphan' -Encoding utf8
    $orphanFailed = $false
    try {
        & $validator -SkillPath $copy
    }
    catch {
        $orphanFailed = $_.Exception.Message -like 'Unlinked reference files:*'
    }
    Assert-True $orphanFailed 'reference files not linked from SKILL.md must fail validation'
    Remove-Item -LiteralPath $orphanReference -Force

    $badUtf8 = Join-Path $copy 'references\invalid-utf8.md'
    [IO.File]::WriteAllBytes($badUtf8, [byte[]](0x23, 0x20, 0xC3, 0x28))
    $utf8Failed = $false
    try {
        & $validator -SkillPath $copy
    }
    catch {
        $utf8Failed = $_.Exception.Message -like 'File is not valid UTF-8:*'
    }
    Assert-True $utf8Failed 'invalid UTF-8 in the Skill bundle must fail validation'

    Write-Host 'VALIDATOR_TEST_PASS'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = [IO.Path]::GetFullPath($testRoot)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean outside temp: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

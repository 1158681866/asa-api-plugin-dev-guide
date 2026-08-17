$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "ASSERTION FAILED: $Message"
    }
}

function Get-Manifest([string]$Root) {
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $manifest = [ordered]@{}
    Get-ChildItem -LiteralPath $rootPath -Recurse -File | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/')
        $manifest[$relative] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
    return ($manifest | ConvertTo-Json -Compress)
}

$scriptPath = Join-Path $PSScriptRoot 'install-skill.ps1'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source = [IO.Path]::GetFullPath((Join-Path $repoRoot 'skills\asa-api-plugin-dev'))
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("asa-skill-installer-test-" + [guid]::NewGuid().ToString('N'))
$skillsRoot = Join-Path $testRoot 'client-skills'
$backupRoot = "$skillsRoot-backups"
$target = Join-Path $skillsRoot 'asa-api-plugin-dev'
$junctionRoot = Join-Path $testRoot 'source-alias'
$completed = $false
$originalHome = $HOME

try {
    & $scriptPath -SkillsRoot $skillsRoot
    Assert-True (Test-Path -LiteralPath (Join-Path $target 'SKILL.md') -PathType Leaf) 'initial install must copy SKILL.md'
    Assert-True ((Get-Manifest $source) -eq (Get-Manifest $target)) 'initial deployment manifest must match canonical source'

    $reinstallFailed = $false
    try {
        & $scriptPath -SkillsRoot $skillsRoot
    }
    catch {
        $reinstallFailed = $_.Exception.Message -like 'Skill already exists:*'
    }
    Assert-True $reinstallFailed 'existing deployment must not be overwritten without -Replace'

    $beforeWhatIf = Get-Manifest $target
    & $scriptPath -SkillsRoot $skillsRoot -Replace -WhatIf
    Assert-True ((Get-Manifest $target) -eq $beforeWhatIf) 'Replace -WhatIf must not modify the deployment'
    Assert-True (-not (Test-Path -LiteralPath $backupRoot)) 'Replace -WhatIf must not create a backup'

    Add-Content -LiteralPath (Join-Path $target 'SKILL.md') -Value "`nlocal-change"
    & $scriptPath -SkillsRoot $skillsRoot -Replace

    $backups = @(Get-ChildItem -LiteralPath (Join-Path $backupRoot 'asa-api-plugin-dev') -Directory)
    Assert-True ($backups.Count -eq 1) 'replace must create exactly one backup outside the discovery root'
    Assert-True ((Get-Content -Raw -LiteralPath (Join-Path $backups[0].FullName 'SKILL.md')) -match 'local-change') 'backup must preserve local changes'
    Assert-True (-not ((Get-Content -Raw -LiteralPath (Join-Path $target 'SKILL.md')) -match 'local-change')) 'replacement must use canonical source'
    Assert-True ((Get-Manifest $source) -eq (Get-Manifest $target)) 'replacement manifest must match canonical source'
    Assert-True (@(Get-ChildItem -LiteralPath $skillsRoot -Recurse -File -Filter 'SKILL.md').Count -eq 1) 'discovery root must contain exactly one SKILL.md after replacement'

    $explicitRoot = Join-Path $testRoot 'explicit'
    $explicitTarget = Join-Path $explicitRoot 'asa-api-plugin-dev'
    & $scriptPath -Destination $explicitTarget
    Assert-True (Test-Path -LiteralPath (Join-Path $explicitTarget 'SKILL.md') -PathType Leaf) 'explicit destination install must work'

    $trailingRoot = Join-Path $testRoot 'trailing-skills'
    & $scriptPath -SkillsRoot ($trailingRoot + [IO.Path]::DirectorySeparatorChar)
    Add-Content -LiteralPath (Join-Path $trailingRoot 'asa-api-plugin-dev\SKILL.md') -Value "`ntrailing-change"
    & $scriptPath -SkillsRoot ($trailingRoot + [IO.Path]::DirectorySeparatorChar) -Replace
    Assert-True (Test-Path -LiteralPath (Join-Path "$trailingRoot-backups" 'asa-api-plugin-dev') -PathType Container) 'trailing separator must still place backup outside discovery root'

    $trailingDestination = Join-Path (Join-Path $testRoot 'trailing-destination') 'asa-api-plugin-dev'
    & $scriptPath -Destination ($trailingDestination + [IO.Path]::DirectorySeparatorChar)
    Assert-True (Test-Path -LiteralPath (Join-Path $trailingDestination 'SKILL.md') -PathType Leaf) 'Destination with a trailing separator must install successfully'

    $whatIfRoot = Join-Path $testRoot 'whatif'
    & $scriptPath -SkillsRoot $whatIfRoot -WhatIf
    Assert-True (-not (Test-Path -LiteralPath $whatIfRoot)) 'WhatIf must not write files'

    $fakeHome = Join-Path $testRoot 'fake-home'
    Set-Variable -Name HOME -Value $fakeHome -Scope Global -Force
    try {
        & $scriptPath -SkillsRoot '~/.agents/skills'
        $expectedTildeTarget = Join-Path $fakeHome '.agents\skills\asa-api-plugin-dev'
        Assert-True (Test-Path -LiteralPath (Join-Path $expectedTildeTarget 'SKILL.md') -PathType Leaf) 'leading ~/ must expand to the current user home'

        $tildeUserFailed = $false
        try {
            & $scriptPath -SkillsRoot '~another-user/skills' -WhatIf
        }
        catch {
            $tildeUserFailed = $_.Exception.Message -like 'Unsupported user-home path syntax:*'
        }
        Assert-True $tildeUserFailed '~user syntax must be rejected instead of resolving relative to the repository'
    }
    finally {
        Set-Variable -Name HOME -Value $originalHome -Scope Global -Force
    }

    $nestedDestinationFailed = $false
    try {
        & $scriptPath -Destination (Join-Path $source 'asa-api-plugin-dev') -WhatIf
    }
    catch {
        $nestedDestinationFailed = $_.Exception.Message -like 'Source and destination must not overlap:*'
    }
    Assert-True $nestedDestinationFailed 'destination inside canonical source must be rejected before staging'

    $wrongLeafFailed = $false
    try {
        & $scriptPath -Destination (Join-Path $testRoot 'wrong-name') -WhatIf
    }
    catch {
        $wrongLeafFailed = $_.Exception.Message -like "Destination folder name must match the Skill name*"
    }
    Assert-True $wrongLeafFailed 'destination leaf must match the Skill name'

    $wrongCaseFailed = $false
    try {
        & $scriptPath -Destination (Join-Path $testRoot 'ASA-API-PLUGIN-DEV') -WhatIf
    }
    catch {
        $wrongCaseFailed = $_.Exception.Message -like "Destination folder name must match the Skill name*"
    }
    Assert-True $wrongCaseFailed 'destination leaf casing must exactly match the Skill name'

    $fileTargetRoot = Join-Path $testRoot 'file-target'
    New-Item -ItemType Directory -Path $fileTargetRoot -Force | Out-Null
    $fileTarget = Join-Path $fileTargetRoot 'asa-api-plugin-dev'
    Set-Content -LiteralPath $fileTarget -Value 'not a directory'
    $fileTargetFailed = $false
    try {
        & $scriptPath -Destination $fileTarget -Replace -WhatIf
    }
    catch {
        $fileTargetFailed = $_.Exception.Message -like 'Destination exists but is not a directory:*'
    }
    Assert-True $fileTargetFailed 'existing destination file must be rejected'

    New-Item -ItemType Junction -Path $junctionRoot -Target (Split-Path -Parent $source) | Out-Null
    $junctionFailed = $false
    try {
        & $scriptPath -SkillsRoot $junctionRoot -Replace -WhatIf
    }
    catch {
        $junctionFailed = $_.Exception.Message -like 'Refusing destination through a symbolic link or junction:*'
    }
    Assert-True $junctionFailed 'destination routed through a junction must be rejected before ShouldProcess'

    $completed = $true
}
finally {
    if ($HOME -ne $originalHome) {
        Set-Variable -Name HOME -Value $originalHome -Scope Global -Force
    }
    if (Test-Path -LiteralPath $junctionRoot) {
        [IO.Directory]::Delete($junctionRoot)
    }
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = [IO.Path]::GetFullPath($testRoot)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean outside temp: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

if ($completed) {
    Write-Host 'INSTALLER_TEST_PASS'
}

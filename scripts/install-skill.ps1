[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'SkillsRoot')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'SkillsRoot')]
    [string]$SkillsRoot,

    [Parameter(Mandatory = $true, ParameterSetName = 'Destination')]
    [string]$Destination,

    [string]$BackupRoot,

    [switch]$Replace
)

$ErrorActionPreference = 'Stop'
$skillName = 'asa-api-plugin-dev'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source = [IO.Path]::GetFullPath((Join-Path $repoRoot "skills\$skillName"))

function Expand-UserPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }
    if ($Path -eq '~') {
        if ([string]::IsNullOrWhiteSpace($HOME)) { throw 'Cannot expand ~ because HOME is unavailable.' }
        return $HOME
    }
    if ($Path.StartsWith('~\') -or $Path.StartsWith('~/')) {
        if ([string]::IsNullOrWhiteSpace($HOME)) { throw 'Cannot expand ~ because HOME is unavailable.' }
        return Join-Path $HOME $Path.Substring(2)
    }
    if ($Path.StartsWith('~')) {
        throw "Unsupported user-home path syntax: $Path"
    }
    return $Path
}

function Get-NormalizedDirectoryPath([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $pathRoot = [IO.Path]::GetPathRoot($fullPath)
    while ($fullPath.Length -gt $pathRoot.Length -and ($fullPath.EndsWith('\') -or $fullPath.EndsWith('/'))) {
        $fullPath = $fullPath.Substring(0, $fullPath.Length - 1)
    }
    return $fullPath
}

function Get-ComparablePath([string]$Path) {
    return Get-NormalizedDirectoryPath $Path
}

function Test-PathIsSameOrUnder([string]$Candidate, [string]$Parent) {
    $candidatePath = Get-ComparablePath $Candidate
    $parentPath = Get-ComparablePath $Parent
    if ($candidatePath.Equals($parentPath, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $parentPrefix = $parentPath + [IO.Path]::DirectorySeparatorChar
    return $candidatePath.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparsePointInExistingAncestors([string]$Path, [string]$Label) {
    $current = [IO.Path]::GetFullPath($Path)
    while (-not [string]::IsNullOrWhiteSpace($current)) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing $Label through a symbolic link or junction: $($item.FullName)"
            }
        }

        $parent = [IO.Directory]::GetParent($current)
        if ($null -eq $parent -or $parent.FullName.Equals($current, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = $parent.FullName
    }
}

function Assert-SafeChild([string]$Candidate, [string]$Parent, [string]$Label) {
    $candidatePath = Get-ComparablePath $Candidate
    $parentPath = Get-ComparablePath $Parent
    if (-not (Test-PathIsSameOrUnder $candidatePath $parentPath) -or $candidatePath.Equals($parentPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing unsafe $Label path: $candidatePath"
    }
}

function Get-DirectoryManifest([string]$Root) {
    $rootPath = Get-ComparablePath $Root
    $entries = [Collections.Generic.List[string]]::new()
    Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($rootPath.Length).TrimStart('\', '/').Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        $entries.Add("$relative=$hash")
    }
    return ($entries -join "`n")
}

if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md') -PathType Leaf)) {
    throw "Skill source is invalid: $source"
}
Assert-NoReparsePointInExistingAncestors $source 'canonical source'
$sourceReparseEntries = @(Get-ChildItem -LiteralPath $source -Recurse -Force | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
if ($sourceReparseEntries.Count -gt 0) {
    throw "Canonical source contains a symbolic link or junction: $($sourceReparseEntries[0].FullName)"
}

if ($PSCmdlet.ParameterSetName -eq 'SkillsRoot') {
    $targetRoot = Get-NormalizedDirectoryPath (Expand-UserPath $SkillsRoot)
    $target = Get-NormalizedDirectoryPath (Join-Path $targetRoot $skillName)
}
else {
    $target = Get-NormalizedDirectoryPath (Expand-UserPath $Destination)
    $targetRoot = Get-NormalizedDirectoryPath (Split-Path -Parent $target)
}

if (-not ([IO.Path]::GetFileName($target)).Equals($skillName, [StringComparison]::Ordinal)) {
    throw "Destination folder name must match the Skill name '$skillName': $target"
}

$targetPathRoot = [IO.Path]::GetPathRoot($target)
if ([string]::IsNullOrWhiteSpace($targetRoot) -or (Get-ComparablePath $target).Equals((Get-ComparablePath $targetPathRoot), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing unsafe destination: $target"
}

if ((Test-PathIsSameOrUnder $target $source) -or (Test-PathIsSameOrUnder $source $target)) {
    throw "Source and destination must not overlap: source=$source destination=$target"
}
Assert-NoReparsePointInExistingAncestors $targetRoot 'destination'
Assert-NoReparsePointInExistingAncestors $target 'destination'

$targetExists = Test-Path -LiteralPath $target
if ($targetExists -and -not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "Destination exists but is not a directory: $target"
}
if ($targetExists -and -not $Replace) {
    throw "Skill already exists: $target. Review local changes, then re-run with -Replace to create a backup and replace it."
}

$resolvedBackupRoot = $null
$backup = $null
if ($targetExists) {
    $resolvedBackupRoot = if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
        Get-NormalizedDirectoryPath "$targetRoot-backups"
    }
    else {
        Get-NormalizedDirectoryPath (Expand-UserPath $BackupRoot)
    }

    if (Test-PathIsSameOrUnder $resolvedBackupRoot $targetRoot) {
        throw "BackupRoot must be outside the Agent discovery root: $resolvedBackupRoot"
    }
    if ((Test-PathIsSameOrUnder $resolvedBackupRoot $source) -or (Test-PathIsSameOrUnder $source $resolvedBackupRoot)) {
        throw "BackupRoot must not overlap the canonical source: $resolvedBackupRoot"
    }
    if (-not ([IO.Path]::GetPathRoot($resolvedBackupRoot)).Equals([IO.Path]::GetPathRoot($targetRoot), [StringComparison]::OrdinalIgnoreCase)) {
        throw "BackupRoot must be on the same volume as the destination: $resolvedBackupRoot"
    }
    Assert-NoReparsePointInExistingAncestors $resolvedBackupRoot 'backup destination'

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $backup = Get-NormalizedDirectoryPath (Join-Path (Join-Path $resolvedBackupRoot $skillName) $timestamp)
    Assert-SafeChild $backup $resolvedBackupRoot 'backup'
}

$stage = Get-NormalizedDirectoryPath (Join-Path $targetRoot ".$skillName.install-$([guid]::NewGuid().ToString('N'))")
Assert-SafeChild $stage $targetRoot 'staging'
$movedExisting = $false

if (-not $PSCmdlet.ShouldProcess($target, "Install Agent Skill from $source")) {
    return
}

try {
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $stage -Recurse

    if (-not (Test-Path -LiteralPath (Join-Path $stage 'SKILL.md') -PathType Leaf)) {
        throw "Staged Skill is invalid: $stage"
    }
    if ((Get-DirectoryManifest $source) -ne (Get-DirectoryManifest $stage)) {
        throw "Staged Skill manifest does not match the canonical source: $stage"
    }

    if ($targetExists) {
        if (Test-Path -LiteralPath $backup) {
            throw "Backup destination already exists: $backup"
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
        Move-Item -LiteralPath $target -Destination $backup
        $movedExisting = $true
    }

    Move-Item -LiteralPath $stage -Destination $target
}
catch {
    $originalError = $_
    $recoveryErrors = [Collections.Generic.List[string]]::new()

    if ($movedExisting) {
        try {
            if (Test-Path -LiteralPath $target) {
                throw "Cannot restore backup because destination now exists: $target"
            }
            if (-not (Test-Path -LiteralPath $backup)) {
                throw "Cannot restore missing backup: $backup"
            }
            Move-Item -LiteralPath $backup -Destination $target
        }
        catch {
            $recoveryErrors.Add("rollback failed: $($_.Exception.Message)")
        }
    }

    if (Test-Path -LiteralPath $stage) {
        try {
            Assert-SafeChild $stage $targetRoot 'staging cleanup'
            Remove-Item -LiteralPath $stage -Recurse -Force
        }
        catch {
            $recoveryErrors.Add("staging cleanup failed: $($_.Exception.Message)")
        }
    }

    if ($recoveryErrors.Count -gt 0) {
        throw "Install failed: $($originalError.Exception.Message); recovery errors: $($recoveryErrors -join '; ')"
    }
    throw $originalError
}

Write-Host "Installed Agent Skill: $target"
if ($backup) {
    Write-Host "Previous deployment backup: $backup"
}
Write-Host 'Refresh or restart the target Agent client if it does not discover the Skill immediately.'

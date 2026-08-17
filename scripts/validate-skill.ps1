param(
    [string]$SkillPath = (Join-Path (Join-Path $PSScriptRoot '..') 'skills\asa-api-plugin-dev')
)

$ErrorActionPreference = 'Stop'
$skill = [IO.Path]::GetFullPath($SkillPath)
$skillFile = Join-Path $skill 'SKILL.md'
$strictUtf8 = [Text.UTF8Encoding]::new($false, $true)

function Read-StrictUtf8([string]$Path) {
    try {
        return [IO.File]::ReadAllText($Path, $strictUtf8)
    }
    catch [Text.DecoderFallbackException] {
        throw "File is not valid UTF-8: $Path"
    }
}

function Test-PathIsUnderReferences([string]$Candidate, [string]$SkillRoot) {
    $referencesRoot = [IO.Path]::GetFullPath((Join-Path $SkillRoot 'references')).TrimEnd('\', '/')
    $candidatePath = [IO.Path]::GetFullPath($Candidate)
    return $candidatePath.StartsWith($referencesRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
    throw "SKILL.md not found: $skillFile"
}

$textExtensions = @('.md', '.yaml', '.yml', '.json', '.jsonc', '.ps1', '.py', '.txt')
Get-ChildItem -LiteralPath $skill -Recurse -File -Force | Where-Object {
    $textExtensions -contains $_.Extension.ToLowerInvariant()
} | ForEach-Object {
    [void](Read-StrictUtf8 $_.FullName)
}

$text = Read-StrictUtf8 $skillFile
$match = [regex]::Match($text, '\A---\r?\n(?<yaml>.*?)\r?\n---\r?\n', [Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $match.Success) {
    throw 'SKILL.md must start with YAML frontmatter delimited by --- lines.'
}

$yaml = $match.Groups['yaml'].Value
$nameMatch = [regex]::Match($yaml, '(?m)^name:\s*["'']?(?<value>[^"''\r\n]+)["'']?\s*$')
$descriptionMatch = [regex]::Match($yaml, '(?m)^description:\s*["'']?(?<value>[^\r\n]+?)["'']?\s*$')

if (-not $nameMatch.Success) { throw 'Missing frontmatter field: name' }
if (-not $descriptionMatch.Success) { throw 'Missing frontmatter field: description' }

$name = $nameMatch.Groups['value'].Value.Trim()
$description = $descriptionMatch.Groups['value'].Value.Trim()
$folderName = Split-Path -Leaf $skill

if ($name.Length -gt 64 -or $name -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
    throw "Invalid Skill name: $name"
}
if ($folderName -cne $name) {
    throw "Skill folder '$folderName' must match frontmatter name '$name'."
}
if ($description.Length -lt 1 -or $description.Length -gt 1024) {
    throw "Description length must be 1-1024 characters; actual=$($description.Length)."
}

$missing = [Collections.Generic.List[string]]::new()
$directReferences = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$markdownFiles = @($skillFile) + @(Get-ChildItem -LiteralPath (Join-Path $skill 'references') -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)

foreach ($markdownFile in $markdownFiles) {
    $markdownText = Read-StrictUtf8 $markdownFile
    $linkMatches = [regex]::Matches($markdownText, '\]\((?<target>[^)\r\n]+)\)')
    foreach ($link in $linkMatches) {
        $targetText = $link.Groups['target'].Value.Trim()
        if ($targetText.StartsWith('<') -and $targetText.EndsWith('>')) {
            $targetText = $targetText.Substring(1, $targetText.Length - 2)
        }
        if ($targetText -match '^(?:https?://|mailto:|data:|javascript:|#)') {
            continue
        }

        $pathPart = ($targetText -split '[#?]', 2)[0]
        if ([string]::IsNullOrWhiteSpace($pathPart)) {
            continue
        }

        $relative = [Uri]::UnescapeDataString($pathPart).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $candidate = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $markdownFile) $relative))
        if (-not $candidate.StartsWith($skill + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Skill reference escapes the Skill root: $relative"
        }
        if (-not (Test-Path -LiteralPath $candidate)) {
            $sourceRelative = $markdownFile.Substring($skill.Length).TrimStart('\', '/').Replace('\', '/')
            $missing.Add("$sourceRelative -> $pathPart")
            continue
        }

        if ($markdownFile.Equals($skillFile, [StringComparison]::OrdinalIgnoreCase) -and (Test-PathIsUnderReferences $candidate $skill)) {
            [void]$directReferences.Add([IO.Path]::GetFullPath($candidate))
        }
    }
}
if ($missing.Count -gt 0) {
    throw "Missing Skill references: $($missing -join ', ')"
}

$orphanReferences = @(Get-ChildItem -LiteralPath (Join-Path $skill 'references') -Recurse -File -Filter '*.md' | Where-Object {
    -not $directReferences.Contains([IO.Path]::GetFullPath($_.FullName))
} | ForEach-Object { $_.FullName.Substring($skill.Length).TrimStart('\', '/').Replace('\', '/') })
if ($orphanReferences.Count -gt 0) {
    throw "Unlinked reference files: $($orphanReferences -join ', ')"
}

$lineCount = ($text -split '\r?\n').Count
if ($lineCount -gt 500) {
    Write-Warning "SKILL.md has $lineCount lines; Agent Skills recommends keeping it below 500 lines."
}

Write-Host "AGENT_SKILL_VALIDATION_PASS name=$name lines=$lineCount"

param(
    [ValidateSet("import-gemini", "export-gemini", "install-codex", "sync-all", "list")]
    [string]$Action = "list",
    [string[]]$SkillNames
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sharedRoot = Join-Path $repoRoot "skills"
$geminiRoot = Join-Path $repoRoot ".gemini\skills"
$codexInstallRoot = Join-Path $HOME ".codex\skills"

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-SkillDirs([string]$Root) {
    if (-not (Test-Path -LiteralPath $Root)) {
        return @()
    }

    return Get-ChildItem -LiteralPath $Root -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") }
}

function Resolve-SkillSelection([string]$Root) {
    $dirs = Get-SkillDirs $Root
    if (-not $SkillNames -or $SkillNames.Count -eq 0) {
        return $dirs
    }

    return $dirs | Where-Object { $SkillNames -contains $_.Name }
}

function Copy-SkillDir([string]$SourceDir, [string]$TargetRoot) {
    Ensure-Dir $TargetRoot

    $sourceItem = Get-Item -LiteralPath $SourceDir
    $targetDir = Join-Path $TargetRoot $sourceItem.Name

    if (Test-Path -LiteralPath $targetDir) {
        Remove-Item -LiteralPath $targetDir -Recurse -Force
    }

    Copy-Item -LiteralPath $SourceDir -Destination $targetDir -Recurse -Force
    Write-Host ("Synced {0} -> {1}" -f $SourceDir, $targetDir)
}

function Import-FromGemini {
    $selected = Resolve-SkillSelection $geminiRoot
    foreach ($skill in $selected) {
        Copy-SkillDir $skill.FullName $sharedRoot
    }
}

function Export-ToGemini {
    $selected = Resolve-SkillSelection $sharedRoot
    foreach ($skill in $selected) {
        Copy-SkillDir $skill.FullName $geminiRoot
    }
}

function Install-ToCodex {
    $selected = Resolve-SkillSelection $sharedRoot
    foreach ($skill in $selected) {
        Copy-SkillDir $skill.FullName $codexInstallRoot
    }
}

switch ($Action) {
    "list" {
        Write-Host "Shared:"
        Get-SkillDirs $sharedRoot | ForEach-Object { Write-Host ("  " + $_.Name) }
        Write-Host "Gemini:"
        Get-SkillDirs $geminiRoot | ForEach-Object { Write-Host ("  " + $_.Name) }
        if (Test-Path -LiteralPath $codexInstallRoot) {
            Write-Host "Codex install target:"
            Get-SkillDirs $codexInstallRoot | ForEach-Object { Write-Host ("  " + $_.Name) }
        }
    }
    "import-gemini" { Import-FromGemini }
    "export-gemini" { Export-ToGemini }
    "install-codex" { Install-ToCodex }
    "sync-all" {
        Export-ToGemini
    }
}

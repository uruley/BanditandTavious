param(
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$requiredFiles = @(
    "AGENTS.md",
    "project.godot",
    "docs/ai/current-state.md",
    "docs/ai/neo_goal.md",
    "docs/ai/neo_scoreboard.md",
    "tools/neo_loop.ps1"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

$projectLines = Get-Content "project.godot"
$mainSceneLine = $projectLines | Where-Object { $_ -match '^run/main_scene=' } | Select-Object -First 1
$mainScene = $null
if ($mainSceneLine) {
    $mainScene = ($mainSceneLine -replace '^run/main_scene="', '') -replace '"$', ''
}

$sceneLoadStatus = $false
if ($mainScene) {
    if ($mainScene -like "res://*" -and $mainScene.EndsWith(".tscn")) {
        $sceneRelativePath = $mainScene -replace '^res://', ''
        $sceneLoadStatus = Test-Path $sceneRelativePath
    }
}

$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
$gitModifiedCount = $null
if ($gitAvailable) {
    $gitStatus = git status --short
    $gitModifiedCount = @($gitStatus).Count
}

$errorCount = 0
if (-not (Test-Path "project.godot")) {
    $errorCount++
}
$errorCount += $missingFiles.Count
if (-not $sceneLoadStatus) {
    $errorCount++
}

$result = [PSCustomObject]@{
    timestamp_utc       = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    repo_root           = $repoRoot
    has_project         = (Test-Path "project.godot")
    main_scene          = $mainScene
    scene_load_status   = $sceneLoadStatus
    error_count         = $errorCount
    required_files_ok   = ($missingFiles.Count -eq 0)
    missing_files       = $missingFiles
    git_available       = $gitAvailable
    git_modified_count  = $gitModifiedCount
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 3
    exit 0
}

Write-Host "Neo Check"
Write-Host "Repo Root: $($result.repo_root)"
Write-Host "Main Scene: $($result.main_scene)"
Write-Host "Scene Load Status: $($result.scene_load_status)"
Write-Host "Error Count: $($result.error_count)"
Write-Host "Required Files OK: $($result.required_files_ok)"
if ($missingFiles.Count -gt 0) {
    Write-Host "Missing Files:"
    foreach ($file in $missingFiles) {
        Write-Host "  - $file"
    }
}
if ($gitAvailable) {
    Write-Host "Git Modified Count: $gitModifiedCount"
} else {
    Write-Host "Git Modified Count: git unavailable"
}

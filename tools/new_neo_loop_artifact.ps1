param(
    [int]$LoopIndex = 1,
    [string]$Goal = "",
    [string]$ActiveScene = "",
    [string]$RecommendedNextLoop = "",
    [string]$BeforeJson = "",
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$artifactRoot = "logs/neo_loops"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$artifactPath = Join-Path $artifactRoot "$($stamp)_loop_$LoopIndex"
New-Item -ItemType Directory -Force -Path $artifactPath | Out-Null

$createdUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"

$proposal = @"
# Neo Loop Proposal

- Created UTC: $createdUtc
- Loop Index: $LoopIndex
- Goal: $Goal
- Active Scene: $ActiveScene
- Recommended Next Loop: $RecommendedNextLoop

## Proposed Change

- TODO: Record the one small change Neo will attempt.

## Expected Evidence

- TODO: Record the check, metric, screenshot, or log that should prove the change helped.
"@

$decision = @"
# Neo Loop Decision

- Decision: pending
- Recommendation: pending
- Decided UTC: pending

## Reasons

- Pending evaluation.

## Follow-Up

- Pending decision.
"@

$lesson = @"
# Neo Loop Lesson

- Promotion Target: none
- Status: pending

## Lesson

- No durable lesson recorded yet.
"@

$metadata = [PSCustomObject]@{
    schema_version = 1
    created_utc = $createdUtc
    loop_index = $LoopIndex
    goal = $Goal
    active_scene = $ActiveScene
    recommended_next_loop = $RecommendedNextLoop
    status = "created"
}

Set-Content -Path (Join-Path $artifactPath "proposal.md") -Value $proposal -Encoding UTF8
Set-Content -Path (Join-Path $artifactPath "decision.md") -Value $decision -Encoding UTF8
Set-Content -Path (Join-Path $artifactPath "lesson.md") -Value $lesson -Encoding UTF8
$metadata | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $artifactPath "metadata.json") -Encoding UTF8

if (-not [string]::IsNullOrWhiteSpace($BeforeJson)) {
    Set-Content -Path (Join-Path $artifactPath "before.json") -Value $BeforeJson -Encoding UTF8
}

if ($PassThru) {
    Write-Output $artifactPath
} else {
    Write-Host "Created Neo loop artifact: $artifactPath"
}

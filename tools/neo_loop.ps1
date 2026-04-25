param(
    [int]$MaxLoops = 1
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$currentStatePath = "docs/ai/current-state.md"
$goalPath = "docs/ai/neo_goal.md"
$scoreboardPath = "docs/ai/neo_scoreboard.md"
$checkPath = Join-Path $PSScriptRoot "neo_check.ps1"

function Get-TaggedLines {
    param(
        [string]$Path,
        [string]$Prefix
    )

    if (-not (Test-Path $Path)) {
        return @()
    }

    return @(Get-Content $Path | Where-Object { $_.TrimStart().StartsWith($Prefix) })
}

function Get-ReasonableGitLimit {
    param(
        [int]$BeforeCount
    )

    if ($BeforeCount -lt 0) {
        return 5
    }

    return ($BeforeCount + 5)
}

function Get-LoopRecommendation {
    param(
        [pscustomobject]$Before,
        [pscustomobject]$After
    )

    $reasons = @()
    $recommendation = "RECOMMEND KEEP"

    $reasonableGitLimit = Get-ReasonableGitLimit -BeforeCount $Before.git_modified_count

    if ($After.required_files_ok -ne $true) {
        $recommendation = "RECOMMEND REVERT"
        $reasons += "required_files_ok is false"
    }

    if ($After.scene_load_status -ne $true) {
        $recommendation = "RECOMMEND REVERT"
        $reasons += "scene_load_status is false"
    }

    if ($After.error_count -gt $Before.error_count) {
        $recommendation = "RECOMMEND REVERT"
        $reasons += "error_count increased from $($Before.error_count) to $($After.error_count)"
    }

    if ($null -ne $After.git_modified_count -and $After.git_modified_count -gt $reasonableGitLimit) {
        if ($recommendation -ne "RECOMMEND REVERT") {
            $recommendation = "UNCERTAIN"
        }
        $reasons += "git_modified_count $($After.git_modified_count) exceeds reasonable loop limit $reasonableGitLimit"
    }

    if ($After.error_count -lt $Before.error_count) {
        $reasons += "error_count improved from $($Before.error_count) to $($After.error_count)"
    }

    if ($After.required_files_ok -eq $true -and $After.scene_load_status -eq $true -and $After.error_count -le $Before.error_count -and ($null -eq $After.git_modified_count -or $After.git_modified_count -le $reasonableGitLimit)) {
        if ($reasons.Count -eq 0) {
            $reasons += "evaluation signals stayed stable"
        }
    } elseif ($recommendation -eq "RECOMMEND KEEP" -and $reasons.Count -eq 0) {
        $recommendation = "UNCERTAIN"
        $reasons += "not enough evaluation signal to recommend keep confidently"
    }

    return [PSCustomObject]@{
        recommendation = $recommendation
        reasonable_git_limit = $reasonableGitLimit
        reasons = $reasons
    }
}

Write-Host "Neo Loop Mode"
Write-Host "Repo Root: $repoRoot"
Write-Host "Max Loops: $MaxLoops"
Write-Host ""
Write-Host "Current State:"
Get-Content $currentStatePath
Write-Host ""
Write-Host "Goal:"
Get-Content $goalPath
Write-Host ""

$keepRules = Get-TaggedLines -Path $scoreboardPath -Prefix "- KEEP_IF:"
$revertRules = Get-TaggedLines -Path $scoreboardPath -Prefix "- REVERT_IF:"

for ($loop = 1; $loop -le $MaxLoops; $loop++) {
    Write-Host ""
    Write-Host "=== Loop $loop of $MaxLoops ==="
    Write-Host "Step 1: Inspect relevant project files."
    Write-Host "Step 2: Propose and apply one small change outside this script."
    Write-Host "Step 3: Return here to checkpoint the repo."
    Write-Host ""

    $before = & $checkPath -AsJson | ConvertFrom-Json
    Write-Host "Checkpoint before review:"
    Write-Host "  Main Scene: $($before.main_scene)"
    Write-Host "  Scene Load Status: $($before.scene_load_status)"
    Write-Host "  Error Count: $($before.error_count)"
    Write-Host "  Required Files OK: $($before.required_files_ok)"
    Write-Host "  Git Modified Count: $($before.git_modified_count)"
    Write-Host ""
    Write-Host "Scoreboard Keep Rules:"
    $keepRules | ForEach-Object { Write-Host "  $_" }
    Write-Host "Scoreboard Revert Rules:"
    $revertRules | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    Read-Host "Apply one small change now, then press Enter to run neo_check.ps1"

    $after = & $checkPath -AsJson | ConvertFrom-Json
    Write-Host ""
    Write-Host "Checkpoint after change:"
    Write-Host "  Main Scene: $($after.main_scene)"
    Write-Host "  Scene Load Status: $($after.scene_load_status)"
    Write-Host "  Error Count: $($after.error_count)"
    Write-Host "  Required Files OK: $($after.required_files_ok)"
    Write-Host "  Git Modified Count: $($after.git_modified_count)"
    Write-Host ""

    $evaluation = Get-LoopRecommendation -Before $before -After $after
    Write-Host "Evaluation Recommendation: $($evaluation.recommendation)"
    Write-Host "  Reasonable Git Limit: $($evaluation.reasonable_git_limit)"
    if ($evaluation.reasons.Count -gt 0) {
        Write-Host "  Reasons:"
        $evaluation.reasons | ForEach-Object { Write-Host "    - $_" }
    }
    Write-Host ""

    $decisionPrompt = "Final decision? Type keep, revert, goal, or stop"
    if ($evaluation.recommendation -eq "RECOMMEND KEEP") {
        $decisionPrompt = "Recommendation is KEEP. Press Enter to accept, or type revert, goal, or stop"
    } elseif ($evaluation.recommendation -eq "RECOMMEND REVERT") {
        $decisionPrompt = "Recommendation is REVERT. Press Enter to accept, or type keep, goal, or stop"
    }

    $decision = Read-Host $decisionPrompt
    if ([string]::IsNullOrWhiteSpace($decision)) {
        if ($evaluation.recommendation -eq "RECOMMEND KEEP") {
            $decision = "keep"
        } elseif ($evaluation.recommendation -eq "RECOMMEND REVERT") {
            $decision = "revert"
        } else {
            $decision = "stop"
        }
    }

    switch ($decision.ToLowerInvariant()) {
        "goal" {
            Write-Host "Goal marked satisfied. Stop Loop Mode and write back durable lessons."
            break
        }
        "stop" {
            Write-Host "Loop Mode stopped by operator."
            break
        }
        "revert" {
            Write-Host "Revert the last small change manually, then update memory only if a durable lesson was learned."
        }
        "keep" {
            Write-Host "Keep the change, then update current state/wiki only with durable lessons."
        }
        default {
            Write-Host "Loop Mode stopped without automatic keep/revert."
            break
        }
    }
}

Write-Host ""
Write-Host "Loop Mode finished."

param(
    [int]$MaxLoops = 1
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$currentStatePath = "docs/ai/current-state.md"
$neoStatePath = "docs/ai/neo_state.json"
$goalPath = "docs/ai/neo_goal.md"
$backlogPath = "docs/ai/neo_backlog.md"
$scoreboardPath = "docs/ai/neo_scoreboard.md"
$checkPath = Join-Path $PSScriptRoot "neo_check.ps1"
$artifactScriptPath = Join-Path $PSScriptRoot "new_neo_loop_artifact.ps1"

function Read-NeoState {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $raw = Get-Content $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    return $raw | ConvertFrom-Json
}

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

    if ($After.milestone_gate -and $After.milestone_gate.status -eq "FAIL") {
        $recommendation = "RECOMMEND REVERT"
        $reasons += "milestone_gate is FAIL"
        if ($After.milestone_gate.fail_reasons) {
            foreach ($reason in @($After.milestone_gate.fail_reasons)) {
                $reasons += "gate fail: $reason"
            }
        }
    } elseif ($After.milestone_gate -and $After.milestone_gate.status -eq "WARN") {
        if ($recommendation -ne "RECOMMEND REVERT") {
            $recommendation = "UNCERTAIN"
        }
        $reasons += "milestone_gate is WARN"
        if ($After.milestone_gate.warn_reasons) {
            foreach ($reason in @($After.milestone_gate.warn_reasons)) {
                $reasons += "gate warn: $reason"
            }
        }
    } elseif ($After.milestone_gate -and $After.milestone_gate.status -eq "PASS") {
        $reasons += "milestone_gate is PASS"
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
Write-Host "Neo State:"
$neoState = Read-NeoState -Path $neoStatePath
if ($neoState) {
    Write-Host "  Active Goal: $($neoState.active_goal)"
    Write-Host "  Active Scene: $($neoState.active_scene)"
    Write-Host "  Main Scene: $($neoState.main_scene)"
    Write-Host "  Recommended Next Loop: $($neoState.recommended_next_loop)"
    if ($neoState.top_blockers) {
        Write-Host "  Top Blockers:"
        @($neoState.top_blockers) | ForEach-Object { Write-Host "    - $_" }
    }
} else {
    Write-Host "  neo_state unavailable"
}
$neoStateGoal = ""
$neoStateActiveScene = ""
$neoStateRecommendedNextLoop = ""
if ($neoState) {
    $neoStateGoal = $neoState.active_goal
    $neoStateActiveScene = $neoState.active_scene
    $neoStateRecommendedNextLoop = $neoState.recommended_next_loop
}
Write-Host ""
Write-Host "Goal:"
Get-Content $goalPath
Write-Host ""
Write-Host "Backlog:"
Get-Content $backlogPath
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

    $beforeJson = & $checkPath -AsJson
    $before = $beforeJson | ConvertFrom-Json
    $artifactPath = & $artifactScriptPath `
        -LoopIndex $loop `
        -Goal $neoStateGoal `
        -ActiveScene $neoStateActiveScene `
        -RecommendedNextLoop $neoStateRecommendedNextLoop `
        -BeforeJson $beforeJson `
        -PassThru

    Write-Host "Loop Artifact: $artifactPath"
    Write-Host "Checkpoint before review:"
    Write-Host "  Main Scene: $($before.main_scene)"
    Write-Host "  Scene Load Status: $($before.scene_load_status)"
    Write-Host "  Error Count: $($before.error_count)"
    Write-Host "  Required Files OK: $($before.required_files_ok)"
    if ($before.milestone_gate) {
        Write-Host "  Milestone Gate: $($before.milestone_gate.status) [$($before.milestone_gate.profile)]"
    }
    Write-Host "  Git Modified Count: $($before.git_modified_count)"
    Write-Host ""
    Write-Host "Scoreboard Keep Rules:"
    $keepRules | ForEach-Object { Write-Host "  $_" }
    Write-Host "Scoreboard Revert Rules:"
    $revertRules | ForEach-Object { Write-Host "  $_" }
    Write-Host ""

    Write-Host ""
    Write-Host "Edit this proposal before or after the change if needed:"
    Write-Host "  $artifactPath\proposal.md"
    Read-Host "Apply one small change now, then press Enter to run neo_check.ps1"

    $afterJson = & $checkPath -AsJson
    $after = $afterJson | ConvertFrom-Json
    Set-Content -Path (Join-Path $artifactPath "after.json") -Value $afterJson -Encoding UTF8
    Write-Host ""
    Write-Host "Checkpoint after change:"
    Write-Host "  Main Scene: $($after.main_scene)"
    Write-Host "  Scene Load Status: $($after.scene_load_status)"
    Write-Host "  Error Count: $($after.error_count)"
    Write-Host "  Required Files OK: $($after.required_files_ok)"
    if ($after.milestone_gate) {
        Write-Host "  Milestone Gate: $($after.milestone_gate.status) [$($after.milestone_gate.profile)]"
    }
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

    $result = [PSCustomObject]@{
        schema_version = 1
        status = "evaluated"
        loop_index = $loop
        artifact_path = $artifactPath
        evaluated_utc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
        decision = $decision.ToLowerInvariant()
        before = $before
        after = $after
        evaluation = $evaluation
    }
    $result | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $artifactPath "result.json") -Encoding UTF8

    $decisionLines = @(
        "# Neo Loop Decision",
        "",
        "- Decision: $($decision.ToLowerInvariant())",
        "- Recommendation: $($evaluation.recommendation)",
        "- Decided UTC: $((Get-Date).ToUniversalTime().ToString("s") + "Z")",
        "",
        "## Reasons",
        ""
    )
    if ($evaluation.reasons.Count -gt 0) {
        foreach ($reason in $evaluation.reasons) {
            $decisionLines += "- $reason"
        }
    } else {
        $decisionLines += "- No evaluation reasons recorded."
    }
    $decisionLines += ""
    $decisionLines += "## Follow-Up"
    $decisionLines += ""
    $decisionLines += "- Update `lesson.md` only if this loop produced durable knowledge."
    Set-Content -Path (Join-Path $artifactPath "decision.md") -Value $decisionLines -Encoding UTF8

    $stopLoop = $false
    switch ($decision.ToLowerInvariant()) {
        "goal" {
            Write-Host "Goal marked satisfied. Stop Loop Mode and write back durable lessons."
            $stopLoop = $true
        }
        "stop" {
            Write-Host "Loop Mode stopped by operator."
            $stopLoop = $true
        }
        "revert" {
            Write-Host "Revert the last small change manually, then update memory only if a durable lesson was learned."
        }
        "keep" {
            Write-Host "Keep the change, then update current state/wiki only with durable lessons."
        }
        default {
            Write-Host "Loop Mode stopped without automatic keep/revert."
            $stopLoop = $true
        }
    }

    if ($stopLoop) {
        break
    }
}

Write-Host ""
Write-Host "Loop Mode finished."

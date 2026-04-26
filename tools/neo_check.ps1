param(
    [switch]$AsJson,
    [string]$GateProfileOverride = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$requiredFiles = @(
    "AGENTS.md",
    "project.godot",
    "docs/ai/current-state.md",
    "docs/ai/neo_goal.md",
    "docs/ai/neo_backlog.md",
    "docs/ai/neo_scoreboard.md",
    "docs/ai/neo_state.json",
    "tools/new_neo_loop_artifact.ps1",
    "tools/register_neo_visual_evidence.ps1",
    "tools/neo_loop.ps1"
)

$neoStatePath = "docs/ai/neo_state.json"

function Convert-ResPathToProjectPath {
    param(
        [string]$ResPath
    )

    if ([string]::IsNullOrWhiteSpace($ResPath)) {
        return $null
    }

    if ($ResPath -like "res://*") {
        return ($ResPath -replace '^res://', '')
    }

    return $ResPath
}

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

function Read-JsonFile {
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

function Get-LatestLoopArtifact {
    param(
        [string]$RootPath
    )

    if (-not (Test-Path $RootPath)) {
        return $null
    }

    return Get-ChildItem -Path $RootPath -Directory |
        Sort-Object -Property Name -Descending |
        Select-Object -First 1
}

function Get-LatestFile {
    param(
        [string]$RootPath,
        [string]$Filter
    )

    if (-not (Test-Path $RootPath)) {
        return $null
    }

    return Get-ChildItem -Path $RootPath -Recurse -File -Filter $Filter |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
}

function Read-AIMetricsSummary {
    param(
        [string]$RootPath
    )

    $latestMetrics = Get-LatestFile -RootPath $RootPath -Filter "*.jsonl"
    if (-not $latestMetrics) {
        return [PSCustomObject]@{
            metrics_present = $false
            latest_metrics_path = $null
            latest_metrics_updated = $null
            total_events = 0
            invalid_json_lines = 0
            interaction_count = 0
            successful_interaction_count = 0
            weapon_success_count = 0
            shot_count = 0
            shot_hit_count = 0
            route_visit_count = 0
            unique_waypoint_count = 0
            build_event_count = 0
            build_completed_count = 0
            stuck_event_count = 0
        }
    }

    $totalEvents = 0
    $invalidJsonLines = 0
    $interactionCount = 0
    $successfulInteractionCount = 0
    $weaponSuccessCount = 0
    $shotCount = 0
    $shotHitCount = 0
    $routeVisitCount = 0
    $waypoints = @{}
    $buildEventCount = 0
    $buildCompletedCount = 0
    $stuckEventCount = 0

    foreach ($line in Get-Content $latestMetrics.FullName) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        try {
            $event = $trimmed | ConvertFrom-Json
        } catch {
            $invalidJsonLines++
            continue
        }

        $totalEvents++
        $eventType = [string]$event.type
        $goal = [string]$event.goal
        $result = [string]$event.result

        if ($eventType -eq "interaction_complete") {
            $interactionCount++
            if ($result.ToLowerInvariant() -eq "success") {
                $successfulInteractionCount++
                if ($goal.ToLowerInvariant() -eq "weapon") {
                    $weaponSuccessCount++
                }
            }
        }

        if ($eventType -eq "shot_fired") {
            $shotCount++
            if ($result.ToLowerInvariant() -eq "hit") {
                $shotHitCount++
            }
        }

        if ($eventType -eq "route_visit") {
            $routeVisitCount++
            $target = [string]$event.target
            if (-not [string]::IsNullOrWhiteSpace($target)) {
                $waypoints[$target] = $true
            }
        }

        if ($eventType.StartsWith("build_")) {
            $buildEventCount++
            if ($eventType -eq "build_completed") {
                $buildCompletedCount++
            }
        }

        if ($eventType -eq "stuck") {
            $stuckEventCount++
        }
    }

    return [PSCustomObject]@{
        metrics_present = $true
        latest_metrics_path = $latestMetrics.FullName
        latest_metrics_updated = $latestMetrics.LastWriteTime.ToString("s")
        total_events = $totalEvents
        invalid_json_lines = $invalidJsonLines
        interaction_count = $interactionCount
        successful_interaction_count = $successfulInteractionCount
        weapon_success_count = $weaponSuccessCount
        shot_count = $shotCount
        shot_hit_count = $shotHitCount
        route_visit_count = $routeVisitCount
        unique_waypoint_count = $waypoints.Count
        build_event_count = $buildEventCount
        build_completed_count = $buildCompletedCount
        stuck_event_count = $stuckEventCount
    }
}

function Read-GodotLogSummary {
    param(
        [string]$RootPath
    )

    $latestLog = Get-LatestFile -RootPath $RootPath -Filter "*.log"
    if (-not $latestLog) {
        return [PSCustomObject]@{
            log_present = $false
            latest_log_path = $null
            latest_log_updated = $null
            error_line_count = 0
            warning_line_count = 0
        }
    }

    $errorLineCount = 0
    $warningLineCount = 0
    foreach ($line in Get-Content $latestLog.FullName) {
        if ($line -match "(?i)(ERROR|SCRIPT ERROR|FATAL|CRASH)") {
            $errorLineCount++
        }
        if ($line -match "(?i)(WARNING|WARN:)") {
            $warningLineCount++
        }
    }

    return [PSCustomObject]@{
        log_present = $true
        latest_log_path = $latestLog.FullName
        latest_log_updated = $latestLog.LastWriteTime.ToString("s")
        error_line_count = $errorLineCount
        warning_line_count = $warningLineCount
    }
}

function Get-LatestBatchSummary {
    param(
        [string]$RootPath
    )

    $latestBatchSummary = Get-LatestFile -RootPath $RootPath -Filter "batch_summary.json"
    if (-not $latestBatchSummary) {
        return [PSCustomObject]@{
            batch_summary_present = $false
            latest_batch_summary_path = $null
            latest_batch_summary_updated = $null
            valid_runs = $null
            average_score = $null
            total_build_completed = $null
            total_stuck_events = $null
            total_route_visits = $null
            total_shots = $null
            total_shot_hits = $null
        }
    }

    $summary = Read-JsonFile -Path $latestBatchSummary.FullName
    return [PSCustomObject]@{
        batch_summary_present = $true
        latest_batch_summary_path = $latestBatchSummary.FullName
        latest_batch_summary_updated = $latestBatchSummary.LastWriteTime.ToString("s")
        valid_runs = $summary.valid_runs
        average_score = $summary.average_score
        total_build_completed = $summary.total_build_completed
        total_stuck_events = $summary.total_stuck_events
        total_route_visits = $summary.total_route_visits
        total_shots = $summary.total_shots
        total_shot_hits = $summary.total_shot_hits
    }
}

function Get-LatestVisualEvidence {
    param(
        [string]$RootPath
    )

    $visualEvidenceRoot = Join-Path $RootPath "visual_evidence"
    if (Test-Path $visualEvidenceRoot) {
        $latestManifest = Get-ChildItem -Path $visualEvidenceRoot -Recurse -File -Filter "manifest.json" |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestManifest) {
            $manifest = Read-JsonFile -Path $latestManifest.FullName
            $evidencePath = $null
            $evidenceExists = $false
            if ($manifest -and -not [string]::IsNullOrWhiteSpace($manifest.evidence_path)) {
                $evidencePath = [string]$manifest.evidence_path
                $evidenceExists = Test-Path $evidencePath
            }

            return [PSCustomObject]@{
                live_visual_evidence_present = $evidenceExists
                latest_visual_evidence_path = $evidencePath
                latest_visual_evidence_updated = $latestManifest.LastWriteTime.ToString("s")
                latest_visual_evidence_manifest_path = $latestManifest.FullName
                latest_visual_evidence_type = if ($manifest) { $manifest.evidence_type } else { $null }
                latest_visual_evidence_scene = if ($manifest) { $manifest.scene } else { $null }
                latest_visual_evidence_claim = if ($manifest) { $manifest.claim } else { $null }
            }
        }
    }

    $extensions = @("*.png", "*.jpg", "*.jpeg", "*.webp")
    $matches = @()
    foreach ($extension in $extensions) {
        if (Test-Path $RootPath) {
            $matches += Get-ChildItem -Path $RootPath -Recurse -File -Filter $extension
        }
    }

    $latestVisual = $matches | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    if (-not $latestVisual) {
        return [PSCustomObject]@{
            live_visual_evidence_present = $false
            latest_visual_evidence_path = $null
            latest_visual_evidence_updated = $null
            latest_visual_evidence_manifest_path = $null
            latest_visual_evidence_type = $null
            latest_visual_evidence_scene = $null
            latest_visual_evidence_claim = $null
        }
    }

    return [PSCustomObject]@{
        live_visual_evidence_present = $true
        latest_visual_evidence_path = $latestVisual.FullName
        latest_visual_evidence_updated = $latestVisual.LastWriteTime.ToString("s")
        latest_visual_evidence_manifest_path = $null
        latest_visual_evidence_type = "unregistered_media"
        latest_visual_evidence_scene = $null
        latest_visual_evidence_claim = $null
    }
}

function Get-MilestoneGate {
    param(
        [string]$GateProfile,
        [pscustomobject]$MilestoneEvidence,
        [int]$RepoErrorCount,
        [bool]$RequiredFilesOk,
        [bool]$SceneLoadStatus,
        [bool]$NeoStateOk,
        [string]$LatestLoopArtifactPath,
        [string]$LatestLoopStatus
    )

    $failReasons = @()
    $warnReasons = @()
    $passReasons = @()
    $normalizedProfile = $GateProfile
    if ([string]::IsNullOrWhiteSpace($normalizedProfile)) {
        $normalizedProfile = "conservative"
    }
    $normalizedProfile = $normalizedProfile.ToLowerInvariant()

    if ($RepoErrorCount -gt 0) {
        $failReasons += "repo error_count is $RepoErrorCount"
    }
    if ($RequiredFilesOk -ne $true) {
        $failReasons += "required_files_ok is false"
    }
    if ($SceneLoadStatus -ne $true) {
        $failReasons += "main scene load status is false"
    }
    if ($NeoStateOk -ne $true) {
        $failReasons += "neo_state_ok is false"
    }
    if ($MilestoneEvidence.ai_invalid_json_lines -gt 0) {
        $failReasons += "AI metrics contain $($MilestoneEvidence.ai_invalid_json_lines) invalid JSON lines"
    }
    if (-not [string]::IsNullOrWhiteSpace($LatestLoopArtifactPath) -and $LatestLoopStatus -ne "evaluated") {
        $failReasons += "latest loop artifact exists but status is '$LatestLoopStatus'"
    }

    $milestoneSignalPresent = (
        $MilestoneEvidence.weapon_milestone_seen -eq $true -or
        $MilestoneEvidence.combat_milestone_seen -eq $true -or
        $MilestoneEvidence.route_milestone_seen -eq $true -or
        $MilestoneEvidence.build_milestone_seen -eq $true
    )

    switch ($normalizedProfile) {
        "neo_kernel" {
            if ([string]::IsNullOrWhiteSpace($LatestLoopArtifactPath)) {
                $warnReasons += "no loop artifact has been created yet"
            } elseif ($LatestLoopStatus -eq "evaluated") {
                $passReasons += "latest loop artifact is evaluated"
            }
        }
        "lyra_ai_headless" {
            if ($MilestoneEvidence.lyra_metrics_present -ne $true) {
                $failReasons += "lyra_ai_headless requires AI metrics JSONL evidence"
            }
            if (-not $milestoneSignalPresent) {
                $failReasons += "lyra_ai_headless requires at least one gameplay milestone signal"
            } else {
                $passReasons += "headless gameplay milestone signal is present"
            }
            if ($MilestoneEvidence.latest_godot_log_error_line_count -gt 0) {
                $warnReasons += "latest Godot log has $($MilestoneEvidence.latest_godot_log_error_line_count) error lines"
            }
            if ($MilestoneEvidence.stuck_events_detected -eq $true) {
                $warnReasons += "stuck events detected in latest headless milestone evidence"
            }
        }
        "lyra_visual" {
            if ($MilestoneEvidence.live_visual_evidence_present -ne $true) {
                $failReasons += "lyra_visual requires registered live visual evidence"
            } elseif ([string]::IsNullOrWhiteSpace($MilestoneEvidence.latest_visual_evidence_manifest_path)) {
                $failReasons += "lyra_visual requires a visual evidence manifest"
            } else {
                $passReasons += "registered live visual evidence is present"
            }
            if ($MilestoneEvidence.latest_godot_log_error_line_count -gt 0) {
                $warnReasons += "latest Godot log has $($MilestoneEvidence.latest_godot_log_error_line_count) error lines"
            }
        }
        "sandbox_terrain" {
            if ($MilestoneEvidence.live_visual_evidence_present -ne $true) {
                $failReasons += "sandbox_terrain requires live/runtime visual evidence"
            } else {
                $passReasons += "sandbox terrain visual evidence is present"
            }
            if ($SceneLoadStatus -eq $true) {
                $passReasons += "main sandbox scene exists"
            }
        }
        "persistent_world" {
            if ($MilestoneEvidence.latest_godot_log_present -ne $true) {
                $warnReasons += "persistent_world has no latest Godot log evidence"
            }
            if ($MilestoneEvidence.live_visual_evidence_present -ne $true) {
                $warnReasons += "persistent_world has no live visual evidence yet"
            }
            $passReasons += "persistent_world gate profile is available but needs project-specific save/load evidence fields"
        }
        default {
            if ($MilestoneEvidence.lyra_metrics_present -ne $true) {
                $warnReasons += "no Lyra AI metrics JSONL evidence found"
            }
            if ($MilestoneEvidence.latest_godot_log_error_line_count -gt 0) {
                $warnReasons += "latest Godot log has $($MilestoneEvidence.latest_godot_log_error_line_count) error lines"
            }
            if ($MilestoneEvidence.live_visual_evidence_present -ne $true) {
                $warnReasons += "live visual evidence is missing"
            }
            if ($MilestoneEvidence.stuck_events_detected -eq $true) {
                $warnReasons += "stuck events detected in latest milestone evidence"
            }
            if ($milestoneSignalPresent) {
                $passReasons += "at least one gameplay milestone signal is present"
            } else {
                $warnReasons += "no gameplay milestone signal is present"
            }
        }
    }

    if ($RepoErrorCount -eq 0 -and $RequiredFilesOk -eq $true -and $SceneLoadStatus -eq $true -and $NeoStateOk -eq $true) {
        $passReasons += "repo health checks are clean"
    }

    $status = "PASS"
    if ($failReasons.Count -gt 0) {
        $status = "FAIL"
    } elseif ($warnReasons.Count -gt 0) {
        $status = "WARN"
    }

    return [PSCustomObject]@{
        status = $status
        profile = $normalizedProfile
        fail_reasons = $failReasons
        warn_reasons = $warnReasons
        pass_reasons = $passReasons
        milestone_signal_present = $milestoneSignalPresent
    }
}

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

$neoState = Read-NeoState -Path $neoStatePath
$neoStateOk = $false
$neoStateIssues = @()
$neoActiveGoal = $null
$neoActiveScene = $null
$neoActiveGateProfile = $null
$neoRecommendedNextLoop = $null
$neoMainSceneMatchesProject = $false
$neoActiveSceneLoadStatus = $false
$latestLoopArtifact = Get-LatestLoopArtifact -RootPath "logs/neo_loops"
$latestLoopArtifactPath = $null
$latestLoopDecision = $null
$latestLoopRecommendation = $null
$latestLoopStatus = $null
$latestLoopCreatedUtc = $null
$aiMetricsSummary = Read-AIMetricsSummary -RootPath "logs"
$godotLogSummary = Read-GodotLogSummary -RootPath "logs"
$latestBatchSummary = Get-LatestBatchSummary -RootPath "logs"
$visualEvidenceSummary = Get-LatestVisualEvidence -RootPath "logs"
$milestoneEvidence = [PSCustomObject]@{
    lyra_metrics_present = $aiMetricsSummary.metrics_present
    latest_ai_metrics_path = $aiMetricsSummary.latest_metrics_path
    latest_ai_metrics_updated = $aiMetricsSummary.latest_metrics_updated
    ai_total_events = $aiMetricsSummary.total_events
    ai_invalid_json_lines = $aiMetricsSummary.invalid_json_lines
    ai_interaction_count = $aiMetricsSummary.interaction_count
    ai_successful_interaction_count = $aiMetricsSummary.successful_interaction_count
    ai_weapon_success_count = $aiMetricsSummary.weapon_success_count
    ai_shot_count = $aiMetricsSummary.shot_count
    ai_shot_hit_count = $aiMetricsSummary.shot_hit_count
    ai_route_visit_count = $aiMetricsSummary.route_visit_count
    ai_unique_waypoint_count = $aiMetricsSummary.unique_waypoint_count
    ai_build_event_count = $aiMetricsSummary.build_event_count
    ai_build_completed_count = $aiMetricsSummary.build_completed_count
    ai_stuck_event_count = $aiMetricsSummary.stuck_event_count
    latest_batch_summary_present = $latestBatchSummary.batch_summary_present
    latest_batch_summary_path = $latestBatchSummary.latest_batch_summary_path
    latest_batch_valid_runs = $latestBatchSummary.valid_runs
    latest_batch_average_score = $latestBatchSummary.average_score
    latest_batch_total_build_completed = $latestBatchSummary.total_build_completed
    latest_batch_total_stuck_events = $latestBatchSummary.total_stuck_events
    latest_batch_total_route_visits = $latestBatchSummary.total_route_visits
    latest_batch_total_shots = $latestBatchSummary.total_shots
    latest_batch_total_shot_hits = $latestBatchSummary.total_shot_hits
    latest_godot_log_present = $godotLogSummary.log_present
    latest_godot_log_path = $godotLogSummary.latest_log_path
    latest_godot_log_error_line_count = $godotLogSummary.error_line_count
    latest_godot_log_warning_line_count = $godotLogSummary.warning_line_count
    live_visual_evidence_present = $visualEvidenceSummary.live_visual_evidence_present
    latest_visual_evidence_path = $visualEvidenceSummary.latest_visual_evidence_path
    latest_visual_evidence_manifest_path = $visualEvidenceSummary.latest_visual_evidence_manifest_path
    latest_visual_evidence_type = $visualEvidenceSummary.latest_visual_evidence_type
    latest_visual_evidence_scene = $visualEvidenceSummary.latest_visual_evidence_scene
    latest_visual_evidence_claim = $visualEvidenceSummary.latest_visual_evidence_claim
    build_milestone_seen = ($aiMetricsSummary.build_completed_count -gt 0 -or $latestBatchSummary.total_build_completed -gt 0)
    route_milestone_seen = ($aiMetricsSummary.route_visit_count -gt 0 -or $latestBatchSummary.total_route_visits -gt 0)
    combat_milestone_seen = ($aiMetricsSummary.shot_hit_count -gt 0 -or $latestBatchSummary.total_shot_hits -gt 0)
    weapon_milestone_seen = ($aiMetricsSummary.weapon_success_count -gt 0)
    stuck_events_detected = ($aiMetricsSummary.stuck_event_count -gt 0 -or $latestBatchSummary.total_stuck_events -gt 0)
}

if ($latestLoopArtifact) {
    $latestLoopArtifactPath = $latestLoopArtifact.FullName
    $latestMetadata = Read-JsonFile -Path (Join-Path $latestLoopArtifact.FullName "metadata.json")
    $latestResult = Read-JsonFile -Path (Join-Path $latestLoopArtifact.FullName "result.json")

    if ($latestMetadata) {
        $latestLoopCreatedUtc = $latestMetadata.created_utc
        $latestLoopStatus = $latestMetadata.status
    }

    if ($latestResult) {
        $latestLoopDecision = $latestResult.decision
        $latestLoopRecommendation = $latestResult.evaluation.recommendation
        if (-not [string]::IsNullOrWhiteSpace($latestResult.status)) {
            $latestLoopStatus = $latestResult.status
        }
    }
}

if ($null -eq $neoState) {
    $neoStateIssues += "neo_state_missing_or_unreadable"
} else {
    $neoActiveGoal = $neoState.active_goal
    $neoActiveScene = $neoState.active_scene
    $neoActiveGateProfile = $neoState.active_gate_profile
    $neoRecommendedNextLoop = $neoState.recommended_next_loop

    if ([string]::IsNullOrWhiteSpace($neoState.active_goal)) {
        $neoStateIssues += "active_goal_missing"
    }

    if ([string]::IsNullOrWhiteSpace($neoState.active_scene)) {
        $neoStateIssues += "active_scene_missing"
    } else {
        $neoActiveScenePath = Convert-ResPathToProjectPath -ResPath $neoState.active_scene
        if ($neoActiveScenePath) {
            $neoActiveSceneLoadStatus = Test-Path $neoActiveScenePath
            if (-not $neoActiveSceneLoadStatus) {
                $neoStateIssues += "active_scene_not_found"
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($neoState.active_gate_profile)) {
        $neoStateIssues += "active_gate_profile_missing"
    }

    if ([string]::IsNullOrWhiteSpace($neoState.main_scene)) {
        $neoStateIssues += "main_scene_missing"
    } else {
        $neoMainSceneMatchesProject = ($neoState.main_scene -eq $mainScene)
        if (-not $neoMainSceneMatchesProject) {
            $neoStateIssues += "main_scene_mismatch"
        }
    }

    if (-not $neoState.top_blockers -or @($neoState.top_blockers).Count -eq 0) {
        $neoStateIssues += "top_blockers_missing"
    }

    if (-not $neoState.evidence_paths -or @($neoState.evidence_paths).Count -eq 0) {
        $neoStateIssues += "evidence_paths_missing"
    }

    if ([string]::IsNullOrWhiteSpace($neoState.recommended_next_loop)) {
        $neoStateIssues += "recommended_next_loop_missing"
    }
}

$neoStateOk = ($neoStateIssues.Count -eq 0)
if (-not [string]::IsNullOrWhiteSpace($GateProfileOverride)) {
    $neoActiveGateProfile = $GateProfileOverride
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
if (-not $neoStateOk) {
    $errorCount++
}

$milestoneGate = Get-MilestoneGate `
    -GateProfile $neoActiveGateProfile `
    -MilestoneEvidence $milestoneEvidence `
    -RepoErrorCount $errorCount `
    -RequiredFilesOk ($missingFiles.Count -eq 0) `
    -SceneLoadStatus $sceneLoadStatus `
    -NeoStateOk $neoStateOk `
    -LatestLoopArtifactPath $latestLoopArtifactPath `
    -LatestLoopStatus $latestLoopStatus

$result = [PSCustomObject]@{
    timestamp_utc       = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    repo_root           = $repoRoot
    has_project         = (Test-Path "project.godot")
    main_scene          = $mainScene
    scene_load_status   = $sceneLoadStatus
    error_count         = $errorCount
    required_files_ok   = ($missingFiles.Count -eq 0)
    missing_files       = $missingFiles
    neo_state_ok        = $neoStateOk
    neo_state_issues    = $neoStateIssues
    neo_active_goal     = $neoActiveGoal
    neo_active_scene    = $neoActiveScene
    neo_active_gate_profile = $neoActiveGateProfile
    neo_active_scene_load_status = $neoActiveSceneLoadStatus
    neo_recommended_next_loop = $neoRecommendedNextLoop
    neo_main_scene_matches_project = $neoMainSceneMatchesProject
    latest_loop_artifact = $latestLoopArtifactPath
    latest_loop_status = $latestLoopStatus
    latest_loop_created_utc = $latestLoopCreatedUtc
    latest_loop_decision = $latestLoopDecision
    latest_loop_recommendation = $latestLoopRecommendation
    milestone_evidence = $milestoneEvidence
    milestone_gate = $milestoneGate
    git_available       = $gitAvailable
    git_modified_count  = $gitModifiedCount
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Neo Check"
Write-Host "Repo Root: $($result.repo_root)"
Write-Host "Main Scene: $($result.main_scene)"
Write-Host "Scene Load Status: $($result.scene_load_status)"
Write-Host "Error Count: $($result.error_count)"
Write-Host "Required Files OK: $($result.required_files_ok)"
Write-Host "Neo State OK: $($result.neo_state_ok)"
if ($result.neo_active_goal) {
    Write-Host "Neo Active Goal: $($result.neo_active_goal)"
}
if ($result.neo_active_scene) {
    Write-Host "Neo Active Scene: $($result.neo_active_scene)"
    Write-Host "Neo Active Scene Load Status: $($result.neo_active_scene_load_status)"
}
if ($result.neo_active_gate_profile) {
    Write-Host "Neo Active Gate Profile: $($result.neo_active_gate_profile)"
}
if ($result.neo_recommended_next_loop) {
    Write-Host "Neo Recommended Next Loop: $($result.neo_recommended_next_loop)"
}
if ($result.latest_loop_artifact) {
    Write-Host "Latest Loop Artifact: $($result.latest_loop_artifact)"
    Write-Host "Latest Loop Status: $($result.latest_loop_status)"
    if ($result.latest_loop_decision) {
        Write-Host "Latest Loop Decision: $($result.latest_loop_decision)"
    }
    if ($result.latest_loop_recommendation) {
        Write-Host "Latest Loop Recommendation: $($result.latest_loop_recommendation)"
    }
}
Write-Host "Milestone Evidence:"
Write-Host "  Lyra Metrics Present: $($result.milestone_evidence.lyra_metrics_present)"
if ($result.milestone_evidence.latest_ai_metrics_path) {
    Write-Host "  Latest AI Metrics: $($result.milestone_evidence.latest_ai_metrics_path)"
    Write-Host "  AI Events: $($result.milestone_evidence.ai_total_events), Invalid Lines: $($result.milestone_evidence.ai_invalid_json_lines)"
    Write-Host "  Interactions: $($result.milestone_evidence.ai_interaction_count), Successes: $($result.milestone_evidence.ai_successful_interaction_count), Weapon Successes: $($result.milestone_evidence.ai_weapon_success_count)"
    Write-Host "  Shots/Hits: $($result.milestone_evidence.ai_shot_count)/$($result.milestone_evidence.ai_shot_hit_count), Routes: $($result.milestone_evidence.ai_route_visit_count), Build Completed: $($result.milestone_evidence.ai_build_completed_count), Stuck: $($result.milestone_evidence.ai_stuck_event_count)"
}
if ($result.milestone_evidence.latest_batch_summary_present) {
    Write-Host "  Latest Batch Summary: $($result.milestone_evidence.latest_batch_summary_path)"
    Write-Host "  Batch Runs: $($result.milestone_evidence.latest_batch_valid_runs), Avg Score: $($result.milestone_evidence.latest_batch_average_score), Batch Build Completed: $($result.milestone_evidence.latest_batch_total_build_completed), Batch Stuck: $($result.milestone_evidence.latest_batch_total_stuck_events)"
}
if ($result.milestone_evidence.latest_godot_log_present) {
    Write-Host "  Latest Godot Log: $($result.milestone_evidence.latest_godot_log_path)"
    Write-Host "  Log Errors/Warnings: $($result.milestone_evidence.latest_godot_log_error_line_count)/$($result.milestone_evidence.latest_godot_log_warning_line_count)"
}
Write-Host "  Live Visual Evidence Present: $($result.milestone_evidence.live_visual_evidence_present)"
if ($result.milestone_evidence.live_visual_evidence_present) {
    Write-Host "  Latest Visual Evidence: $($result.milestone_evidence.latest_visual_evidence_path)"
    if ($result.milestone_evidence.latest_visual_evidence_manifest_path) {
        Write-Host "  Latest Visual Manifest: $($result.milestone_evidence.latest_visual_evidence_manifest_path)"
        Write-Host "  Visual Type: $($result.milestone_evidence.latest_visual_evidence_type), Scene: $($result.milestone_evidence.latest_visual_evidence_scene)"
        Write-Host "  Visual Claim: $($result.milestone_evidence.latest_visual_evidence_claim)"
    }
}
Write-Host "  Milestones Seen: weapon=$($result.milestone_evidence.weapon_milestone_seen), combat=$($result.milestone_evidence.combat_milestone_seen), route=$($result.milestone_evidence.route_milestone_seen), build=$($result.milestone_evidence.build_milestone_seen), stuck=$($result.milestone_evidence.stuck_events_detected)"
Write-Host "Milestone Gate: $($result.milestone_gate.status) [$($result.milestone_gate.profile)]"
if ($result.milestone_gate.fail_reasons.Count -gt 0) {
    Write-Host "  Fail Reasons:"
    foreach ($reason in $result.milestone_gate.fail_reasons) {
        Write-Host "    - $reason"
    }
}
if ($result.milestone_gate.warn_reasons.Count -gt 0) {
    Write-Host "  Warn Reasons:"
    foreach ($reason in $result.milestone_gate.warn_reasons) {
        Write-Host "    - $reason"
    }
}
if ($result.milestone_gate.pass_reasons.Count -gt 0) {
    Write-Host "  Pass Reasons:"
    foreach ($reason in $result.milestone_gate.pass_reasons) {
        Write-Host "    - $reason"
    }
}
if ($missingFiles.Count -gt 0) {
    Write-Host "Missing Files:"
    foreach ($file in $missingFiles) {
        Write-Host "  - $file"
    }
}
if ($neoStateIssues.Count -gt 0) {
    Write-Host "Neo State Issues:"
    foreach ($issue in $neoStateIssues) {
        Write-Host "  - $issue"
    }
}
if ($gitAvailable) {
    Write-Host "Git Modified Count: $gitModifiedCount"
} else {
    Write-Host "Git Modified Count: git unavailable"
}

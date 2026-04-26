param(
    [int]$Runs = 1,
    [double]$Duration = 18,
    [int]$ActorCount = 6,
    [int]$StartSeed = 4501,
    [string]$OutDir = "logs/lyra_ai_batch",
    [string]$Scene = "res://level/scenes/lyrasandbox.tscn",
    [string]$GodotExe = "C:\Users\ruley\CornersstoneGamingEngine\GTASim\godot_vr\godot_bin\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

New-Item -ItemType Directory -Force $OutDir | Out-Null
$progressPath = Join-Path $OutDir "progress.json"
$runSummariesPath = Join-Path $OutDir "run_summaries.json"
$batchSummaryPath = Join-Path $OutDir "batch_summary.json"

function Write-ProgressFile {
    param(
        [string]$Status,
        [int]$Run,
        [int]$Seed,
        [string]$Message
    )

    [PSCustomObject]@{
        status = $Status
        run = $Run
        runs = $Runs
        seed = $Seed
        message = $Message
        timestamp = (Get-Date).ToString("s")
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $progressPath -Encoding UTF8
}

function Sum-Field {
    param(
        [array]$Items,
        [string]$Field
    )

    $sum = 0.0
    foreach ($item in $Items) {
        $value = $item.$Field
        if ($null -ne $value) {
            $sum += [double]$value
        }
    }
    return $sum
}

$summaries = @()
Write-ProgressFile -Status "starting" -Run 0 -Seed $StartSeed -Message "Starting Lyra AI batch."

for ($run = 1; $run -le $Runs; $run++) {
    $seed = $StartSeed + $run - 1
    $runStem = "run_{0:0000}" -f $run
    $metricsRel = (Join-Path $OutDir "$runStem.jsonl") -replace "\\", "/"
    $godotLogRel = (Join-Path $OutDir "$runStem.godot.log") -replace "\\", "/"
    $summaryRel = (Join-Path $OutDir "$runStem.summary.json") -replace "\\", "/"

    Write-ProgressFile -Status "running" -Run $run -Seed $seed -Message "Running $runStem."
    & $GodotExe --headless --path . --scene $Scene --log-file $godotLogRel -- --ai-test --duration $Duration --ai-count $ActorCount --seed $seed --metrics-path "res://$metricsRel" | Out-Null
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0 -and (Test-Path $metricsRel)) {
        $summaryJson = python skills/godot-ai/scripts/parse_ai_metrics.py $metricsRel --json
        $summaryJson | Set-Content -Path $summaryRel -Encoding UTF8
        $summary = $summaryJson | ConvertFrom-Json
        $summaries += [PSCustomObject]@{
            run = $run
            seed = $seed
            exit_code = $exitCode
            total_events = $summary.total_events
            simple_loop_score = $summary.simple_loop_score
            build_completed_count = $summary.build_completed_count
            build_event_count = $summary.build_event_count
            goal_selected_count = $summary.goal_selected_count
            goal_started_count = $summary.goal_started_count
            goal_completed_count = $summary.goal_completed_count
            goal_failed_count = $summary.goal_failed_count
            goal_cleanup_count = $summary.goal_cleanup_count
            next_goal_selected_count = $summary.next_goal_selected_count
            actor_idle_timeout_count = $summary.actor_idle_timeout_count
            unfinished_goal_count = $summary.unfinished_goal_count
            stuck_event_count = $summary.stuck_event_count
            route_visit_count = $summary.route_visit_count
            unique_waypoint_count = $summary.unique_waypoint_count
            shot_count = $summary.shot_count
            shot_hit_count = $summary.shot_hit_count
            weapon_success = $summary.interactions.weapon.success
            build_success = $summary.interactions.build.success
            summary_path = $summaryRel
            metrics_path = $metricsRel
            log_path = $godotLogRel
        }
        Write-Host ("Run {0}/{1} seed {2}: build={3} stuck={4} score={5}" -f $run, $Runs, $seed, $summary.build_completed_count, $summary.stuck_event_count, $summary.simple_loop_score)
    } else {
        $summaries += [PSCustomObject]@{
            run = $run
            seed = $seed
            exit_code = $exitCode
            total_events = 0
            simple_loop_score = 0
            build_completed_count = 0
            build_event_count = 0
            goal_selected_count = 0
            goal_started_count = 0
            goal_completed_count = 0
            goal_failed_count = 0
            goal_cleanup_count = 0
            next_goal_selected_count = 0
            actor_idle_timeout_count = 0
            unfinished_goal_count = 0
            stuck_event_count = 0
            route_visit_count = 0
            unique_waypoint_count = 0
            shot_count = 0
            shot_hit_count = 0
            weapon_success = 0
            build_success = 0
            summary_path = $summaryRel
            metrics_path = $metricsRel
            log_path = $godotLogRel
        }
        Write-Host ("Run {0}/{1} seed {2}: Godot exit {3}, metrics missing={4}" -f $run, $Runs, $seed, $exitCode, -not (Test-Path $metricsRel))
    }

    $summaries | ConvertTo-Json -Depth 5 | Set-Content -Path $runSummariesPath -Encoding UTF8
    Write-ProgressFile -Status "running" -Run $run -Seed $seed -Message "Finished $runStem."
}

$valid = @($summaries | Where-Object { $_.exit_code -eq 0 -and $_.total_events -gt 0 })
$buildCompletedRuns = @($valid | Where-Object { $_.build_completed_count -gt 0 })
$batchSummary = [PSCustomObject]@{
    runs_requested = $Runs
    valid_runs = $valid.Count
    duration_sec = $Duration
    actor_count = $ActorCount
    start_seed = $StartSeed
    build_completed_runs = $buildCompletedRuns.Count
    total_build_completed = [int](Sum-Field -Items $valid -Field "build_completed_count")
    total_build_events = [int](Sum-Field -Items $valid -Field "build_event_count")
    total_goal_selected = [int](Sum-Field -Items $valid -Field "goal_selected_count")
    total_goal_started = [int](Sum-Field -Items $valid -Field "goal_started_count")
    total_goal_completed = [int](Sum-Field -Items $valid -Field "goal_completed_count")
    total_goal_failed = [int](Sum-Field -Items $valid -Field "goal_failed_count")
    total_goal_cleanup = [int](Sum-Field -Items $valid -Field "goal_cleanup_count")
    total_next_goal_selected = [int](Sum-Field -Items $valid -Field "next_goal_selected_count")
    total_actor_idle_timeout = [int](Sum-Field -Items $valid -Field "actor_idle_timeout_count")
    total_unfinished_goals = [int](Sum-Field -Items $valid -Field "unfinished_goal_count")
    total_stuck_events = [int](Sum-Field -Items $valid -Field "stuck_event_count")
    total_route_visits = [int](Sum-Field -Items $valid -Field "route_visit_count")
    total_shots = [int](Sum-Field -Items $valid -Field "shot_count")
    total_shot_hits = [int](Sum-Field -Items $valid -Field "shot_hit_count")
    total_weapon_success = [int](Sum-Field -Items $valid -Field "weapon_success")
    total_build_success = [int](Sum-Field -Items $valid -Field "build_success")
    average_score = if ($valid.Count -gt 0) { [math]::Round((Sum-Field -Items $valid -Field "simple_loop_score") / $valid.Count, 4) } else { 0 }
}
$batchSummary | ConvertTo-Json -Depth 5 | Set-Content -Path $batchSummaryPath -Encoding UTF8
Write-ProgressFile -Status "completed" -Run $Runs -Seed ($StartSeed + $Runs - 1) -Message "Lyra AI batch completed."
$batchSummary | ConvertTo-Json -Depth 5

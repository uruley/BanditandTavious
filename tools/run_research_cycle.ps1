param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExe,
    [string]$ProjectPath = ".",
    [string]$Scene = "res://level/scenes/TrainingGround.tscn",
    [int]$Cycles = 20,
    [int]$EpisodesPerCycle = 20,
    [double]$EpisodeDuration = 45.0,
    [int]$AnalysisWindow = 10,
    [string]$LogRoot = "logs/research",
    [string]$EvolutionLog = "user://evolution_log.jsonl",
    [string]$SuggestionsPath = "user://evolution_suggestions.json",
    [switch]$ResetLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-UserPath {
    param(
        [string]$PathValue,
        [string]$ProjectRoot
    )
    if ($PathValue.StartsWith("user://")) {
        $suffix = $PathValue.Substring(7)
        return [System.IO.Path]::GetFullPath((Join-Path -Path $ProjectRoot -ChildPath $suffix))
    }
    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }
    return [System.IO.Path]::GetFullPath((Join-Path -Path $ProjectRoot -ChildPath $PathValue))
}

$projectRoot = [System.IO.Path]::GetFullPath($ProjectPath)
$logRootAbs = Resolve-UserPath -PathValue $LogRoot -ProjectRoot $projectRoot
$evolutionLogAbs = Resolve-UserPath -PathValue $EvolutionLog -ProjectRoot $projectRoot
$suggestionsAbs = Resolve-UserPath -PathValue $SuggestionsPath -ProjectRoot $projectRoot

New-Item -ItemType Directory -Path $logRootAbs -Force | Out-Null

if ($ResetLogs) {
    if (Test-Path $evolutionLogAbs) { Remove-Item -LiteralPath $evolutionLogAbs -Force }
    if (Test-Path $suggestionsAbs) { Remove-Item -LiteralPath $suggestionsAbs -Force }
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logRootAbs "run_$runStamp"
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$masterReport = Join-Path $runDir "summary.md"

@(
    "# Research Run $runStamp"
    ""
    "- Project: $projectRoot"
    "- Scene: $Scene"
    "- Cycles: $Cycles"
    "- Episodes per cycle: $EpisodesPerCycle"
    "- Episode duration: $EpisodeDuration"
    "- Evolution log: $evolutionLogAbs"
    "- Suggestions path: $suggestionsAbs"
    ""
) | Set-Content -Path $masterReport -Encoding UTF8

Write-Host "[Research] Starting $Cycles cycles..."

for ($cycle = 1; $cycle -le $Cycles; $cycle++) {
    $seed = Get-Random -Minimum 1 -Maximum 2147483646
    Write-Host "[Research] Cycle $cycle/$Cycles seed=$seed"

    $godotArgs = @(
        "--headless",
        "--path", $projectRoot,
        $Scene,
        "--",
        "--episodes=$EpisodesPerCycle",
        "--duration=$EpisodeDuration",
        "--seed=$seed"
    )

    & $GodotExe @godotArgs
    $godotExit = $LASTEXITCODE
    if ($godotExit -ne 0) {
        throw "Godot headless run failed on cycle $cycle with exit code $godotExit."
    }

    $cycleJson = Join-Path $runDir ("cycle_{0:D2}.json" -f $cycle)
    $cycleMd = Join-Path $runDir ("cycle_{0:D2}.md" -f $cycle)
    $pythonArgs = @(
        "tools/summarize_experiment.py",
        "--log", $evolutionLogAbs,
        "--window", $AnalysisWindow,
        "--cycle", $cycle,
        "--summary-json", $cycleJson,
        "--summary-md", $cycleMd,
        "--suggestions-path", $suggestionsAbs
    )
    python @pythonArgs
    if ($LASTEXITCODE -ne 0) {
        throw "summarize_experiment.py failed on cycle $cycle."
    }

    Add-Content -Path $masterReport -Value ""
    Add-Content -Path $masterReport -Value "---"
    Add-Content -Path $masterReport -Value ""
    Get-Content -Path $cycleMd | Add-Content -Path $masterReport
}

Write-Host "[Research] Complete. Master report: $masterReport"

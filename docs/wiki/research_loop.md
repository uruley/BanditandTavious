# Research Loop (Karpathy Style)

## Goal

Run repeated headless experiment cycles, extract objective signals, identify research gaps, and feed structured suggestions back into the next cycle.

This page is the operational loop for:

1. experiment execution
2. automatic analysis
3. gap detection
4. next-cycle suggestion injection
5. wiki/memory write-back

## Current Runtime Loop Components

- Headless trainer scene: `res://level/scenes/TrainingGround.tscn`
- Episode manager: `res://level/scripts/training_episode_manager.gd`
- Evolution engine: `res://level/scripts/training_evolution_engine.gd`
- Batch orchestrator: `tools/run_research_cycle.ps1`
- Analyzer and suggestion generator: `tools/summarize_experiment.py`

## Data Artifacts

- Evolution log: `user://evolution_log.jsonl`
- Coach override input: `user://evolution_suggestions.json`
- Batch reports: `logs/research/run_YYYYMMDD_HHMMSS/`
  - `summary.md` (all cycles)
  - `cycle_XX.md` / `cycle_XX.json`

## Standard Overnight Command

Use this from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_research_cycle.ps1 `
  -GodotExe "C:\Path\To\Godot_v4.x-stable_win64.exe" `
  -ProjectPath "." `
  -Scene "res://level/scenes/TrainingGround.tscn" `
  -Cycles 20 `
  -EpisodesPerCycle 20 `
  -EpisodeDuration 45 `
  -ResetLogs
```

Notes:

- `-Cycles` controls outer-loop research iterations.
- `-EpisodesPerCycle` controls in-run episode count before each analysis checkpoint.
- `training_episode_manager.gd` accepts CLI args:
  - `--episodes=<int>`
  - `--duration=<float>`
  - `--seed=<int>`

## Gap Detection Logic (Automated)

`tools/summarize_experiment.py` flags:

- flat score trend (stagnation)
- negative trend (regression)
- high variance (instability)
- missing role data

It also writes `user://evolution_suggestions.json` for the next cycle when stagnation/regression is detected.

## How This Supports Destruction Research

For destruction-system research, mirror this same loop shape:

1. create a headless destruction benchmark scene
2. emit per-episode metrics (`fracture_count`, `settle_time`, `fps`, `active_shards`, `collision_failures`)
3. reuse `run_research_cycle.ps1` pattern for repeated runs
4. add a destruction-specific summarizer or extend `summarize_experiment.py`
5. write gaps + next experiment plan back into wiki and `docs/ai/current-state.md`

The key is not one benchmark run; it is repeated run -> measure -> critique -> adjust cycles.

## Write-Back Rule

After each meaningful overnight batch:

1. add conclusions to `docs/wiki/log.md`
2. update relevant domain wiki (`ai_training.md`, `destruction.md`, etc.)
3. update `docs/ai/current-state.md` with live blockers and next run parameters

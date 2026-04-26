# Neo Scoreboard

## Goal

- GOAL: Improve Lyra AI sandbox behavior through small verified systems: navigation/interactions, visible building, combat proof, persistent memory, and a shared life-system spine.

## Baseline

- BASELINE_MAIN_SCENE: `res://level/scenes/Sandbox.tscn`
- BASELINE_AI_SCENE: `res://level/scenes/lyrasandbox.tscn`
- BASELINE_AI_25S: 14 successful interactions, 0 weapon pickups, 21 stuck events, simple loop score `19.6762`.

## Keep If

- KEEP_IF: `error_count <= previous_error_count`
- KEEP_IF: `required_files_ok == true`
- KEEP_IF: `scene_load_status == true`
- KEEP_IF: `git_modified_count` remains reasonable for one small loop change and does not indicate large unrelated churn.
- KEEP_IF: The loop reduces uncertainty, confirms a fact, or improves the operator workflow without broad refactors.
- KEEP_IF: AI interaction count improves without eliminating telemetry.
- KEEP_IF: At least one successful `weapon` interaction is logged during the verification run.

## Revert If

- REVERT_IF: `error_count` increased.
- REVERT_IF: `required_files_ok == false`
- REVERT_IF: `scene_load_status == false`
- REVERT_IF: `git_modified_count` indicates excessive unrelated changes.
- REVERT_IF: The loop makes the current blocker less clear or damages the current runtime path.
- REVERT_IF: AI metrics stop parsing cleanly after the metrics-path fix.

## Latest Check

- STATUS: PASS / KEEP. One-loop life-system audit completed. No shared health/death/recovery spine exists yet; `docs/wiki/life_system.md` now defines the smallest proposed `LifeComponent` slice. Final `tools/neo_check.ps1` still passes under `lyra_ai_headless` with 0 log errors.
- LAST_UPDATED: 2026-04-26

# Neo Scoreboard

## Goal

- GOAL: Improve Lyra AI sandbox navigation/interactions and prove capsule AI weapon pickup through headless loops without broad scene churn.

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

- STATUS: Kept. 30 valid 12-second loops averaged score `104.3337`, 15.8667 interactions, 3.9333 weapon pickups, and 1.3 stuck events. Final 25-second comparison produced 24 interactions, 4 weapon pickups, 5 stuck events, and score `185.52`.
- LAST_UPDATED: 2026-04-25

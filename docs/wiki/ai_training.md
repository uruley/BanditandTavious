# AI Training Pipeline

## Goal

Create a data loop from live NPC behavior in `BanditAI.tscn` to a trainable dataset.

Current pipeline:

1. Runtime logger writes snapshots to `user://bandit_ai_activity.jsonl`.
2. Offline converter writes SQLite tables to `logs/bandit_ai_activity.db`.
3. Training jobs consume `actor_samples` and `actor_transitions`.

The Lyra sandbox Phase 1 AI prototype also writes loop-oriented JSONL metrics to:

- `logs/ai_metrics.jsonl`

Those metrics are summarized with:

```bash
python skills/godot-ai/scripts/parse_ai_metrics.py logs/ai_metrics.jsonl
```

Latest broad-sandbox navigation benchmark:
- `res://level/scenes/lyrasandbox.tscn`
- 6 active AI actors
- roles: `forager`, `hauler`, `scout`
- baseline before the April 25, 2026 loop pass: 14 successful interactions, 0 weapon pickups, 21 stuck events, simple loop score `19.6762`
- 30 valid 12-second improvement loops: average score `104.3337`, average interactions `15.8667`, average weapon pickups `3.9333`, average stuck events `1.3`
- final 25-second comparison run: 24 successful interactions, 4 weapon pickups, 5 stuck events, simple loop score `185.52`

Interpretation: the benchmark now covers broader routes, resource loops, and weapon pickup behavior. Broad navigation is improved but not solved; the remaining stuck events are useful training signals for the next loop. The next structural step is still a real navigation bake or explicit waypoint/corridor graph before deeper utility tuning.

## Runtime Logging

Scene:

- `res://level/scenes/BanditAI.tscn`

Logger:

- `res://level/scripts/bandit_ai_activity_logger.gd`

Output:

- `user://bandit_ai_activity.jsonl`

Snapshot fields include:

- actor name and role
- state label (`attack`, `chase`, `defend`, `escort`, `flee`, `wander`)
- position and velocity
- target point and target name
- distance to target

## SQLite Export

Exporter script:

- `tools/ai_activity_to_sqlite.py`
- `tools/summarize_experiment.py` (loop analysis and gap detection for evolution runs)
- `tools/run_research_cycle.ps1` (headless multi-cycle orchestration)
- `skills/godot-ai/scripts/parse_ai_metrics.py` (Lyra AI JSONL metric summary and simple loop score)

Example command:

```bash
python tools/ai_activity_to_sqlite.py --input bandit_ai_activity.jsonl --db logs/bandit_ai_activity.db --reset
```

Tables:

- `actor_samples`: one row per actor snapshot
- `actor_transitions`: derived `(s_t, a_t, s_t+1)` rows per actor

## First Training Task

Use villager flee behavior as the first ML target.

State (suggested):

- villager position `(x, z)`
- nearest enemy relative position `(dx, dz)`
- villager velocity `(vx, vz)`
- distance to target

Action (suggested):

- movement delta `(action_dx, action_dz)` or normalized direction

Objective:

- imitate current flee policy first (behavior cloning)
- then replace with reward optimization where reward increases with enemy distance and survival time

## Notes

- This project currently uses offline SQLite export instead of direct in-engine SQL writes.
- If in-engine SQLite is needed later, add a dedicated Godot SQLite plugin and keep schema parity with the offline exporter.
- For repeatable overnight improvement loops, use [[research_loop|Research Loop]].

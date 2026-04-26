# AI Training Pipeline

## Goal

Create a data loop from live NPC behavior in `BanditAI.tscn` to a trainable dataset.

The [[persistent_sandbox_ai|Persistent Sandbox AI Master Plan]] changes the long-term order of operations: persistence and structured logs come before model training. SQLite-backed world state, event logs, NPC memories, relationships, schedules, inventory, and world objects should become reliable before the project tries to train a neural NPC policy.

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
- 40-loop follow-up: average score `95.5502`, average interactions `14.9`, average weapon pickups `3.5`, average stuck events `1.35`; `AI_PistolPickup_02` caused 20 of 54 stuck events.
- same-seed 10-loop comparison after moving `AI_PistolPickup_02` inward: average score `98.8507 -> 107.631`, interactions `151 -> 162`, weapon pickups `35 -> 40`, stuck events `12 -> 10`; weapon-target stuck events were eliminated in a fresh 10-loop verification.
- shooting milestone batch: 5 fixed 18-second seeds produced 20 weapon pickups, 117 shots, 95 hits, 0 stuck events, accuracy `0.812`.
- expanded-nav milestone batch: 10 fixed 18-second seeds produced 40 weapon pickups, 131 non-combat interactions, 186 shots, 148 hits, 30 hits on `AI_TargetDummy_02`, 0 stuck events, and average score `333.9355`.
- waypoint-route milestone batch: 5 fixed 30-second sequential seeds produced 30 `route_visit` events, 4 distinct waypoint names in every run (`WP_CentralMarket`, `WP_EastOuter`, `WP_NorthEast`, `WP_SpawnLane`), 20 weapon pickups, 96 shots, 95 hits, 0 stuck events, and 0.9896 shot accuracy.

Interpretation: the benchmark now covers broader routes, named waypoint traversal, resource loops, weapon pickup behavior, first-pass shooting, and a verified expanded combat route. Broad navigation is improved enough for prototype building tests, but the later structural step is still a real navigation bake before deeper combat tactics.

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

`parse_ai_metrics.py` now also reports shooting fields:

- `shot_count`
- `shot_hit_count`
- `shot_accuracy`
- `shot_results`

It also reports route traversal fields:

- `route_visit_count`
- `unique_waypoint_count`
- `visited_waypoints`
- `route_visits_by_actor`

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

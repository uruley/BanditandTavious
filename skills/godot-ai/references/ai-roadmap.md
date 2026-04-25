# Godot AI Roadmap

## Goal

Build a practical AI stack for `BanditandTavious` that starts with simple capsule NPCs in `lyrasandbox` and can grow into combat, vehicles, aircraft, teamwork, and automated loop tuning.

The first target is not believable human intelligence. The first target is measurable NPC agency: agents choose goals, move to targets, interact, update needs/resources, and produce logs that make failures obvious.

## Phase 1: Survival Collection Slice

Scene target:

- `res://level/scenes/lyrasandbox.tscn`

Actor placeholder:

- Capsule or simple `CharacterBody3D`
- Optional label/debug text above the actor
- No final character mesh required

World targets:

- `food`
- `water`
- `resource`
- Optional later: `rest`, `shelter`, `danger`, `weapon`

Actor state:

- `hunger`: rises over time, falls after food interaction
- `thirst`: rises over time, falls after water interaction
- `resource_count`: rises after resource interaction
- `current_goal`: selected high-level goal
- `current_target`: reserved target node
- `stuck_seconds`: time without useful movement

Decision model:

- Utility AI scores possible goals every fixed decision interval.
- Use normalized scores from `0.0` to `1.0`.
- Add decision inertia so goals do not flip every frame.
- Reserve the selected target through a task board before moving.

Execution model:

- FSM states are enough for the first slice:
- `idle`
- `select_goal`
- `move_to_target`
- `interact`
- `recover_or_replan`

Done criteria:

- Three or more NPCs can run at once.
- NPCs choose different targets when reservations are active.
- Food/water/resource interactions complete.
- Metrics prove completions and stuck time.

## Phase 2: Shared Blackboard And Task Board

Add shared world coordination before adding combat complexity.

Task board responsibilities:

- Track available targets by type.
- Reserve targets by actor id.
- Release reservations on completion, timeout, death, or target deletion.
- Track shared team requests like "need food stockpile" or "defend area".

Blackboard facts:

- Known resource locations
- Known threats
- Current team goal
- Nearby allies
- Nearby enemies
- Reserved target id

Done criteria:

- Agents do not dogpile the same resource unless the target allows multiple users.
- Failed or deleted targets do not trap agents.
- Metrics include reservation success/failure counts.

## Phase 3: Weapons And Team Roles

Only add combat after Phase 1 and Phase 2 are stable.

Roles:

- Gatherer: prioritizes survival/resource collection.
- Guard: patrols, detects hostiles, protects gatherers.
- Attacker: pursues and attacks enemies.
- Support: follows allies and helps with revive/heal later.

Combat basics:

- Coarse detection with `Area3D`.
- Line-of-sight confirmation with `RayCast3D`.
- Simple projectile or hitscan attack.
- Cover and squad tactics later, not first.

Done criteria:

- Roles share the same movement, targeting, blackboard, and metrics patterns.
- Combat does not break the collection loop.
- Friendly-fire, idle time, and stuck time are measured.

## Phase 4: Vehicles And Aircraft

Treat vehicles as targets with ownership, mount points, and task capabilities.

Vehicle tasks:

- Reserve vehicle.
- Move to mount point.
- Enter vehicle.
- Drive/fly to destination.
- Exit or hand off vehicle.

Do not make the LLM drive per frame. Vehicles should be controlled by deterministic steering and task scripts. LLMs can later tune parameters or propose route/task changes offline.

Done criteria:

- NPC can reserve and enter a vehicle.
- NPC can complete a simple point-to-point drive using deterministic control.
- Metrics include time to mount, route completion, collision count, and stuck time.

## Phase 5: Loop Mode And OpenRouter Coach

Use the external API as an offline coach, not a frame-by-frame brain.

Recommended loop:

1. Run deterministic benchmark scene with a fixed seed.
2. Parse metrics.
3. Score the run.
4. Ask the cheap OpenRouter model for suggested parameter changes or focused code edits.
5. Apply only bounded changes.
6. Rerun the benchmark with the same seed set.
7. Compare score deltas and keep/revert based on evidence.

The coach should receive summaries, not raw full logs unless needed.

Good coach inputs:

- Metric summary
- Current config values
- Current failing behavior
- Allowed files or config keys to change
- Regression budget

Bad coach inputs:

- Full repo with no constraints
- Per-frame control prompts
- Permission to edit unrelated systems
- Unbounded "make AI better" instructions

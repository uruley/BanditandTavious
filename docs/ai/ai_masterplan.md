# AI Masterplan

Related:
- [[memory|AI Memory]]
- [[current-state|Current State]]
- [[session-notes|Session Notes]]
- [[../wiki/ai_systems|AI Systems]]
- [[../wiki/ai_training|AI Training Pipeline]]
- [[../wiki/persistent_sandbox_ai|Persistent Sandbox AI Master Plan]]

## Direction

Build AI through small, verified gameplay milestones in `res://level/scenes/lyrasandbox.tscn` before migrating behavior into the main multiplayer `Sandbox.tscn` runtime.

Each milestone should add one visible capability, one metrics path, and one verification command. Avoid broad AI rewrites while the runtime player, weapon, and navigation branches are still split.

The longer-term north star from `docs/raw/masterplans/master_plan.pdf` is a persistent sandbox: NPCs should carry out routines, remember important events, reload those memories after restart, and let durable world state change future behavior. SQLite/event persistence should come before any serious model training work.

## Loop Contract

Lyra AI loop claims must prove a full goal lifecycle, not only goal selection:

1. Pick a goal.
2. Start the task.
3. Complete or fail it with a logged reason.
4. Release reservations or carried state cleanly.
5. Select and begin the next useful goal.

Headless loop verification is the default proof path for AI behavior. Metrics should show goal selections, starts, completions, failures, next-goal transitions, stuck events, route visits, shots, pickups, and build events as relevant.

Visual features need visual proof. Use screenshots or recorded editor/windowed runs when the behavior is about visible placement, animation, weapon alignment, building appearance, UI state, terrain/nav visibility, or any claim that cannot be proven from headless JSONL metrics alone.

## Current Baseline

- AI capsules can select utility goals for food, water, resources, weapons, and combat.
- AI can reserve normal targets through `lyra_ai_task_board.gd`.
- AI can pick up `WeaponPickup` scenes through `WeaponInventoryComponent` and hidden `WeaponMaster`.
- AI can fire a weapon at a runtime target dummy and log `shot_fired` metrics.
- AI can deliver resources to a visible runtime build site and complete `BuildSite_Barricade_01`.
- Headless loop verification works when Godot is launched with an explicit repo-local `--log-file`.

## Milestones

### M1: Weapon Pickup

Status: complete.

Proof:
- 40-loop follow-up found and fixed the `AI_PistolPickup_02` nav-boundary stuck cluster.
- Same-seed 10-loop comparison improved weapon pickups from `35` to `40`.

### M2: Basic Shooting

Status: complete.

Scope:
- Add one runtime combat target dummy.
- Let armed AI select a `combat` goal.
- Fire through the existing `WeaponMaster.fire()` cooldown path.
- Resolve first-pass hits with a raycast and log `shot_fired` metrics.

Proof:
- Single 18-second headless run: 4 weapon pickups, 22 shots, 18 hits, 0 stuck events.
- 5-seed 18-second batch: 20 weapon pickups, 117 shots, 95 hits, 0 stuck events, accuracy `0.812`.

### M3: Bigger Navigation

Status: waypoint route layer complete for the prototype; real nav bake remains later work.

Scope:
- Replace or supplement the hand-authored broad nav rectangles with a more reliable route layer.
- Preferred first step: explicit waypoint/corridor graph for the sandbox props and target zones.
- Later step: real Godot nav bake from the saved sandbox collision layout.

Acceptance:
- 10 fixed-seed loops.
- At least 4 weapon pickups per loop.
- At least 12 successful non-combat interactions per loop.
- Average stuck events below 1.0.
- No single target accounts for more than 30% of stuck events.

Proof:
- Expanded generated nav from a 3x3 block into a 6x6 grid with outer target zones.
- Added far target markers and a second combat dummy in the expanded east corridor.
- Added a combat seek-distance filter so actors do not accept overlong combat routes through blocked sandbox geometry.
- 10 fixed 18-second seeds: 40 weapon pickups, 131 non-combat interactions, 186 shots, 148 hits, 30 hits on `AI_TargetDummy_02`, and 0 stuck events.
- Added explicit runtime waypoints and an `explore` goal so scouts actually traverse named route markers instead of only using farther targets.
- Final 5 fixed 30-second sequential seeds after lane tuning: 30 route visits, 4 distinct waypoint names in every run, 20 weapon pickups, 96 shots, 95 hits, and 0 stuck events.

### M4: First Building Ability

Status: prototype complete; expand next.

Scope:
- AI gathers resources.
- AI selects a build site.
- AI spends resources to complete one simple buildable object, currently `BuildSite_Barricade_01`.
- Metrics log `build_started`, `build_resource_delivered`, and `build_completed`.

Acceptance:
- At least one build completed in a 30-second headless run. Passed.
- Build does not block every route to nearby food, water, weapon, or combat targets. Passed after increasing build interaction radius.
- Build behavior does not reduce weapon pickup success below 3 per loop. Passed.

Proof:
- 50 fixed 18-second seeds produced 49/50 completed builds, 196 build events, 200 weapon pickups, 480 shots, 466 hits, and 8 stuck events.
- The failing seed showed haulers stopping 3.5-4.1m short of the build site; increasing `build_distance` to `4.5` fixed that seed.
- Post-fix 10-seed tail batch produced 10/10 completed builds, 0 stuck events, 40 weapon pickups, 97/97 shots hit, and 31 route visits.

### M5: Shared Life System

Status: proposed next.

Scope:
- Add one reusable `LifeComponent` for health, damage, downed/death, recovery, revive, respawn, metrics, and memory events.
- Wire the component to Lyra AI actors and Bachtavious/player damage entrypoints first.
- Keep destructibles on their existing `destroy()` path until living actors have a stable lifecycle.

Acceptance:
- A Lyra AI actor can receive damage through a public `take_damage()` path.
- Metrics include `life_damaged`.
- Metrics include either `life_downed` or `life_died` when health crosses the configured threshold.
- Downed/dead actors stop normal goal execution.
- `tools/neo_check.ps1` still passes after the verification run.

Design:
- See `docs/wiki/life_system.md`.

### M6: Tactical Combat

Status: planned.

Scope:
- Add combat roles: scout/guard/hauler.
- Add firing range bands and simple repositioning.
- Add cover or fallback points only after navigation is more reliable.

Acceptance:
- AI can acquire weapons, move to combat range, shoot, and continue servicing survival/resource goals.
- Combat target selection and hit/miss results are visible in metrics.

### M7: Persistent World Memory

Status: planned.

Scope:
- Add a SQLite-backed world-state layer for the sandbox prototype.
- Store world time, NPC state, events, NPC memories, relationships, schedules, inventory, and world objects.
- Convert meaningful gameplay events into NPC memories and relationship changes.
- Keep LLM/reflection work on a slow loop; do not put LLM calls in per-frame movement or combat.

First vertical slice:
- Player steals from a shopkeeper.
- Theft event is logged.
- Shopkeeper memory and relationship change are persisted.
- Game closes and reloads.
- Shopkeeper behavior changes because the memory was loaded.

Acceptance:
- The persisted database contains the event, memory, and relationship change.
- Reloaded runtime behavior differs from the pre-theft state.
- Logs and screenshot evidence prove the before/after behavior.

## Operating Rule

The next loop should either extend `M4: First Building Ability` from one runtime barricade into multiple visible blueprint/build tasks or begin `M6: Persistent World Memory` with the narrow shopkeeper-theft slice. Building placement should stay anchored to the verified waypoint/corridor layer until a real sandbox nav bake replaces the hand-authored grid.

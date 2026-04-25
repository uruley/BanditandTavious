# AI Systems

Related:
- [[index|Wiki Index]]
- [[player_setup|Player Setup]]
- [[animations|Animations]]
- [[multiplayer|Multiplayer]]

## Scope

This page captures the preferred Godot 4 NPC AI direction for this project:
- enemies
- friendly companions
- villagers / civilian NPCs

The goal is a reusable NPC architecture with shared core systems and role-specific decision layers, not one monolithic AI script.

## Recommended Architecture

Use a hybrid setup:
- shared NPC base actor
- shared sensing and navigation components
- shared blackboard/runtime data
- Behavior Trees for combat and reactive agents
- utility-style scoring for villagers and higher-level companion priorities

NotebookLM research pointed most strongly toward `LimboAI` as the practical Godot 4 choice for Behavior Trees plus Hierarchical State Machines while still allowing custom task logic in GDScript.

## Technical Implementation Details

### 1. AI Abilities (Abilities System)
- **Composition over Inheritance:** Give NPCs specialized nodes like `AttackComponent` or `DodgeComponent`. Scale by adding these "bricks" to any entity.
- **Modular Action Tasks:** In Behavior Trees (e.g., LimboAI), implement abilities as leaf nodes (`BTAction`). Use tasks like `BTPlayAnimation` and `BTAwaitAnimation` to sequence physical actions.
- **Action Overrides:** Use an "escape hatch" in the animation controller to hand off control to a specific component (like a `DodgeComponent`) which handles physics/movement and calls a completion callback.

### 2. Objective Completion & Planning
- **GOAP (Goal-Oriented Action Planning):** Ideal for multi-step goals (e.g., "Get key -> Open door -> Kill boss"). NPCs find their own "path" to a goal by chaining modular actions based on Preconditions and Effects.
- **Blackboard & World State:** Objectives are reached by monitoring a set of facts about the environment stored in a Blackboard (AI's "memory").
- **Decision Inertia:** Avoid rapid oscillations by only re-planning at fixed intervals or when significant world state changes occur.

### 3. Advanced Systems
- **Utility AI:** Best for resource-heavy or survival gameplay where priorities shift constantly. Use response curves to score actions based on "considerations" (e.g., hunger, distance).
- **Hybrid Patterns:** A common industry standard is using **Utility to set high-level priorities** (e.g., "should I fight or flee?") and **Behavior Trees to execute** the specific sub-tasks.
- **Spatial Hashing:** For finding nearby objects (trees, items) efficiently without checking distances to every object in the world.

### 4. Testing & Verification
- **Visual Testing:** Use the LimboAI Debugger for live BT execution views. Implement `Debug Draw 3D` to visualize vision cones, raycasts, and navigation paths.
- **Headless Testing:** Use **GUT (Godot Unit Test)** for command-line verification of AI logic. This is essential for the "Research Loop" and CI/CD.
- **Update Partitioning (Staggering):** Stagger AI updates so only a fraction (e.g., 1/10th) of agents "think" on any given frame. Human reaction time is ~250ms, so 10Hz updates are often sufficient.

## Role Breakdown

### Enemies

Use:
- Behavior Tree for high-level combat logic
- optional nested state machine for local combat states

Good enemy task families:
- patrol
- detect player
- chase
- maintain range
- attack
- take cover
- flee / reposition
- investigate last known position

### Friendly Companions

Use:
- Behavior Tree for execution
- utility scoring for high-level priority selection

Companion priorities usually compete:
- follow player
- assist player target
- revive / heal / help
- avoid blocking player
- retreat / regroup

### Villagers / Civilians

Use:
- schedule-driven routine system
- utility-style action selection inside the current schedule window

Typical villager concerns:
- time of day
- location target
- social / work / idle / sleep behavior
- dialogue availability
- reaction to danger

## Shared Core Systems

### 1. Actor Split

Prefer a controller/body split:
- Pawn / Actor: `CharacterBody3D`, animation hooks, health, movement execution
- Brain / Controller: decision logic, blackboard, task/state orchestration

### 2. Blackboard

Use a shared blackboard-style data container for runtime facts:
- current target
- last known target position
- home position
- current schedule slot
- alert state
- health / stamina / fear flags

### 3. Navigation

Use Godot 4 navigation stack:
- `NavigationAgent3D`
- `NavigationRegion3D` / navigation meshes
- optional agent avoidance where crowding matters

### 4. Perception

Start simple:
- `Area3D` for coarse detection ranges
- `RayCast3D` for line-of-sight confirmation

Recommended perception layers:
- detection radius
- attack / interaction radius
- optional hearing or alert propagation later

### 5. Data-Driven Config

Store per-NPC-type tuning in resources or data structs instead of script forks:
- move speed
- aggro radius
- attack range
- retreat threshold
- schedule definition
- dialogue flags

## Implementation Order

### Phase 1

Build the reusable base:
- base NPC actor scene
- base AI controller
- navigation movement
- simple perception
- simple FSM: idle / patrol / chase / attack

### Phase 2

Introduce proper BT support:
- add LimboAI
- move enemy logic into BT tasks
- add blackboard variables
- add last-known-position investigation

### Phase 3

Add companion-specific logic:
- follow distance bands
- assist target selection
- regroup / catch-up behavior
- anti-blocking spacing

### Phase 4

Add villager systems:
- time system hookup
- schedule resources
- routine movement
- dialogue / social flags
- panic or flee override

### Phase 5

Only later, if needed:
- GOAP for advanced tactical enemies
- richer utility scoring
- smart cover queries
- squad tactics
- LLM-driven dialogue or local AI-assisted NPC speech

## Project Recommendation

For `BanditandTavious`, the first useful vertical slice is:
- one hostile enemy
- one companion follower
- one villager with a simple schedule

They should all share:
- one navigation approach
- one perception pattern
- one blackboard/data layout

They should differ mainly in decision policy and tuning data.

## Lyra Sandbox AI Roadmap

The current AI skill direction starts smaller than the full enemy/companion/villager architecture:
- capsule NPCs in `res://level/scenes/lyrasandbox.tscn`
- simple target markers for `food`, `water`, and `resources`
- Utility AI for high-level goal selection
- a small FSM for execution states like `idle`, `move_to_target`, `interact`, and `replan`
- a shared task board for reservations so NPCs do not dogpile the same target
- JSONL telemetry from the start so Loop Mode can compare behavior with metrics instead of subjective observation

The OpenRouter-backed AI coach should be treated as an offline loop assistant, not a per-frame runtime brain. It should read metric summaries, propose bounded config or script changes, then rerun fixed-seed benchmarks and compare score deltas.

### Implemented Phase 1 Prototype

`res://level/scenes/lyrasandbox.tscn` now contains a `LyraAIPrototype` node with persistent food/water/resource target nodes under `LyraAIPrototype/Targets`. At runtime it creates `AISandboxNavigationRegion` in the real sandbox play area, capsule gatherers, and JSONL metrics logging. The implementation is intentionally isolated from the existing multiplayer player path, but no longer depends on the old isolated test pad by default.

Key scripts:
- `res://level/scripts/lyra_ai_phase1_manager.gd`
- `res://level/scripts/lyra_ai_actor.gd`
- `res://level/scripts/lyra_ai_target.gd`
- `res://level/scripts/lyra_ai_task_board.gd`
- `res://level/scripts/lyra_ai_metrics.gd`

The prototype now uses `NavigationAgent3D` for movement over a generated sandbox nav mesh. The old isolated `AITestPad` remains available only through `--ai-test-pad` for fallback diagnostics.

The current broad-navigation experiment expands to 6 actors and introduces lightweight roles:
- `forager`: biases food and water.
- `hauler`: biases resources.
- `scout`: prefers farther targets to exercise longer travel routes.

Actors now apply short target cooldowns after stuck events so blocked routes do not immediately reselect the same target. This is a diagnostic/recovery layer, not a final navigation solution.

The April 25, 2026 loop pass upgraded the prototype with:
- a larger connected corridor-style generated sandbox nav mesh
- runtime correction of persistent target positions, plus fourth food/water/resource markers
- capacity-aware target reservations
- reachable runtime pistol/rifle pickups for AI
- actor-side `WeaponInventoryComponent` plus hidden `WeaponMaster`
- `weapon` utility goals that reserve and interact with existing `WeaponPickup` nodes
- `--seed` and `--metrics-path` CLI support for repeatable headless batches

Latest headless real-sandbox AI loop results:
- Baseline 25-second run before the pass: 14 successful interactions, 0 weapon pickups, 21 stuck events, parser score `19.6762`.
- 30 valid 12-second loops after improvements: average score `104.3337`, average interactions `15.8667`, average weapon pickups `3.9333`, average stuck events `1.3`.
- Final 25-second comparison run: 24 successful interactions, 4 weapon pickups, 5 stuck events, parser score `185.52`.

The broad nav result is improved but still not final: the generated corridor nav supports larger routes and much more activity, but occasional stuck events remain. The next step is a real nav bake or explicit waypoint/corridor graph derived from actual sandbox collision geometry, rather than more hand-authored rectangles.

## Notes

- NotebookLM notebook: `BanditandTavious Godot AI Systems`
- NotebookLM alias: `godot-ai`
- Initial deep research imported 49 sources into the notebook

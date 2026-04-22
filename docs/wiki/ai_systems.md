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

## Notes

- NotebookLM notebook: `BanditandTavious Godot AI Systems`
- NotebookLM alias: `godot-ai`
- Initial deep research imported 49 sources into the notebook

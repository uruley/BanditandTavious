# Multiplayer Wiki

Related:
- [[index|Wiki Index]]
- [[terrain3d|Terrain3D]]
- [[../ai/memory|AI Memory]]
- [[../ai/current-state|Current State]]

## Purpose

This file is the deep-storage reference for multiplayer behavior in this repo. Use it for spawn flow, authority behavior, scene-level orchestration, and debugging guidance.

## Core Files

- Scene orchestration: `level/scripts/level.gd`
- Player logic: `level/scripts/player.gd`
- Player scene: `level/scenes/player.tscn`
- Network support: `level/scripts/network.gd`
- Main scene: `level/scenes/Mainland.tscn`
- Sandbox test scene: `level/scenes/Sandbox.tscn`

## Spawn Flow

- `level.gd` owns `player_scene`, `players_container`, menu state, and multiplayer chat UI.
- `_add_player()` instantiates `player_scene`, names the node with the peer id, sets `player.position = get_spawn_point()`, and adds it to `players_container`.
- Current spawn generation in `get_spawn_point()` is a fixed scene-aware anchor near `chair.position + SPAWN_OFFSET`, with fallback `Vector3(1.5, 0.05, 12.58)`.
- After spawn, nick, skin, and position sync RPCs are used to initialize the player.

## Authority and Camera Flow

- `player.gd` extends `CharacterBody3D`.
- The player camera is under `SpringArmOffset/SpringArm3D/Camera3D`.
- In `_configure_multiplayer_state()`, the player tries for several frames to stabilize peer id and local authority.
- When the player is local, it sets multiplayer authority to the peer id and forces `Camera3D.current = true`.
- Physics input in `_physics_process()` only runs when `is_multiplayer_authority()` is true.

## Current Network Model

- `network.gd` uses `ENetMultiplayerPeer`, not WebRTC/WebSocket.
- The game uses a listen-server model: the host creates the ENet server and also participates as peer `1`.
- Rooms are implemented by port selection, where room `N` maps to port `8080 + N`.
- The server owns connection orchestration and player spawning.
- Each player node is peer-authoritative for local movement/input once `player.gd` assigns authority to that peer id.
- State replication is RPC-based for setup and selected gameplay events rather than a full server-simulated rollback or state-sync model.

## Movement and Respawn Facts

- Gravity comes from `ProjectSettings.get_setting("physics/3d/default_gravity")`.
- Jump uses `JUMP_VELOCITY`.
- Movement is applied via `move_and_slide()`.
- `_check_fall_and_respawn()` respawns when `global_transform.origin.y < -15.0`.
- `_respawn_point` in `player.gd` is currently `Vector3(0, 5, 0)`.

## Chat and Menu Interaction

- `level.gd` controls chat visibility and menu visibility.
- In `player.gd`, movement is frozen when chat is visible and the player is on the floor.
- `toggle_chat()` and `_input()` in `level.gd` manage chat focus and mouse capture behavior.

## Recent Debugging History

- One collision issue was caused by the player collider existing but being disabled in `player.tscn`.
- Scene diagnosis was initially misleading because the inspected world scene was not the same as the active debugging scene.
- Current multiplayer and spawn debugging should account for Terrain3D in `Sandbox.tscn`, not only classic floor meshes.

## Multiplayer Debug Checklist

When multiplayer behavior looks wrong, verify:

1. Which scene is actually running.
2. Whether the player node exists under `PlayersContainer`.
3. Whether the node name matches the peer id.
4. Whether multiplayer authority is set to the expected peer id.
5. Whether the local camera becomes current.
6. Whether spawn position is valid for the active world geometry.
7. Whether sync RPCs for nick, skin, and position ran.

## Editing Guidance

- Be cautious when changing spawn behavior because world geometry differs between `Mainland.tscn` and `Sandbox.tscn`.
- If spawn logic changes, update both `docs/ai/memory.md` and this file.
- If authority or camera flow changes, record the exact expected behavior here so future sessions can diagnose regressions quickly.

## Open Questions

- Should spawn logic become explicitly scene-aware instead of relying on the current chair/flight-pad anchor?
- Should respawn move to a terrain-aware or checkpoint-based system instead of a fixed `_respawn_point`?

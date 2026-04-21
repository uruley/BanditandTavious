# AI Memory

Related:
- [[current-state|Current State]]
- [[lessons|Lessons]]
- [[session-notes|Session Notes]]
- [[../wiki/index|Wiki Index]]

## Project

- Name: `BanditandTavious`
- Engine: Godot 4.3
- Project type: 3D multiplayer prototype built from a Godot multiplayer template and extended with room-based multiplayer and chat features.

## Important Scenes

- Main project scene in `project.godot`: `res://level/scenes/Sandbox.tscn`
- `Sandbox.tscn` is both the current project main scene and the active Terrain3D/multiplayer debugging scene.
- Player scene: `res://level/scenes/player.tscn`
- Quaternius test level: `res://level/scenes/quaternius_test_level.tscn`
- Quaternius test player: `res://level/scenes/quaternius_test_player.tscn`
- Playable Quaternius mannequin wrapper: `res://assets/animations/quaternius/Unreal-Godot/GodotManny.tscn`
- Fresh Manny flat-ground test level: `res://level/scenes/godot_manny_test_level.tscn`
- Fresh Manny flat-ground player scene: `res://level/scenes/godot_manny_player.tscn`

## Important Scripts

- `level/scripts/level.gd`: scene-level multiplayer flow, spawning, menu, chat
- `level/scripts/player.gd`: movement, gravity, jump, camera authority, respawn, shooting
- `level/scripts/network.gd`: multiplayer networking support
- `level/scripts/terrain_dig.gd`: Terrain3D interaction helper
- `level/scripts/quaternius_test_player.gd`: lightweight third-person spherical-gravity movement and animation test harness for the Quaternius mannequin import
- `level/scripts/godot_manny_player.gd`: flat-ground third-person Manny controller that instantiates the imported Quaternius model at runtime

## Multiplayer Facts

- Players are instantiated from `player_scene` in `level/scripts/level.gd`.
- Spawns are currently server-assigned from `get_spawn_point()` in `level/scripts/level.gd`, which returns a fixed scene anchor near `chair.position + SPAWN_OFFSET` and falls back to `Vector3(1.5, 0.05, 12.58)`.
- Room selection is port-based in `level/scripts/level.gd`: room `N` maps to ENet port `8080 + N`.
- The host/server owns player instantiation in `PlayersContainer`, while each spawned player node sets multiplayer authority to its peer id in `player.gd`.
- Local camera authority is set in `player.gd` after replicated peer id stabilization.

## Terrain3D Facts

- `Sandbox.tscn` uses a `Terrain3D` node under `Environment`.
- Terrain3D expects a `data_directory` that stores terrain region `.res` files.
- The repo-local Terrain3D data directory is `res://terrain_data`.
- `Sandbox.tscn` has been wired to `res://terrain_data` and to `res://terrain_data/assets.tres`.
- `TerrainDigger` in `Sandbox.tscn` is wired to the `Terrain3D` node.

See also: [[../wiki/terrain3d|Terrain3D]]

## Debugging Workflow

- For collision bugs, verify:
  1. the actual scene being run
  2. the collider state in the player scene
  3. the floor or terrain collision source in the active scene
  4. spawn location relative to the walkable surface
- For UI/menu bugs, inspect sibling `Control` overlays and their `mouse_filter`/visibility state, not just the target buttons.
- If Godot MCP is unavailable, inspect scene and script files directly in the repo and mark live verification as pending.

## Memory Workflow

- Agents must read the `docs/ai/*.md` files before substantial work.
- Agents should write back only durable knowledge, not noisy transcripts.

## Quaternius Character Facts

- `assets/animations/quaternius/Unreal-Godot/GodotManny.tscn` is no longer only a visual `Node3D`; it is now a playable `CharacterBody3D` wrapper around `UAL1_Standard.glb`.
- The wrapper reuses `level/scripts/quaternius_test_player.gd` with `Model`, `CollisionShape3D`, and `SpringArmOffset/SpringArm3D/Camera3D` nodes that match the script's expected paths.
- `level/scenes/quaternius_test_level.tscn` now instantiates `GodotManny.tscn` for direct testing.
- The fresh test path is `level/scenes/godot_manny_test_level.tscn`, which uses a flat `CSGBox3D` floor plus `godot_manny_test_level.gd` to spawn `godot_manny_player.tscn`.
- `godot_manny_player.gd` avoids the older spherical-gravity spawn/orientation logic and is the preferred script for simple floor-based Manny testing.
- `level/scenes/godot_manny_test_level.tscn` now directly instances `godot_manny_player.tscn` as a visible `Player` child in the editor.

# Current State

Related:
- [[memory|AI Memory]]
- [[lessons|Lessons]]
- [[session-notes|Session Notes]]
- [[../wiki/terrain3d|Terrain3D]]
- [[../wiki/multiplayer|Multiplayer]]

## Recent Setup Changes

- The player collision shape in `level/scenes/player.tscn` was re-enabled after it was found disabled.
- `level/scenes/Sandbox.tscn` was updated to use Terrain3D data from `res://terrain_data`.
- `terrain_data` now contains seeded Terrain3D region files and `assets.tres`.
- The temporary diagnostic `CSGBox3D` floor added during collision debugging was removed after Terrain3D wiring was added.
- Added a blank Quaternius character test harness:
- Added a blank Quaternius character test harness:
  - `res://level/scenes/quaternius_test_player.tscn`
  - `res://level/scenes/quaternius_test_level.tscn`
  - `res://level/scripts/quaternius_test_player.gd`
- The Quaternius test level is now being used as a small-planet experiment with a collision-enabled `CSGSphere3D` surface and spawn logic handled in the player script.
- `res://assets/animations/quaternius/Unreal-Godot/GodotManny.tscn` was converted into a playable `CharacterBody3D` wrapper using the Quaternius test player script, collider, and third-person camera rig.
- `res://level/scenes/quaternius_test_level.tscn` now instantiates `GodotManny.tscn` instead of the older wrapper scene for direct verification.
- Added a clean Manny flat-ground test path:
  - `res://level/scenes/godot_manny_player.tscn`
  - `res://level/scripts/godot_manny_player.gd`
  - `res://level/scenes/godot_manny_test_level.tscn`
  - `res://level/scripts/godot_manny_test_level.gd`
- The new flat-ground Manny test scene uses a fixed `PlayerSpawn` over a collision-enabled `CSGBox3D` floor instead of the older spherical-gravity Quaternius test harness.
- `res://level/scenes/godot_manny_test_level.tscn` now contains a direct `Player` scene instance, so the player is visible and editable in the editor scene tree instead of being spawned by script at runtime.
- `project.godot` now points `run/main_scene` to `res://level/scenes/Sandbox.tscn`, which the user identified as the intended project main scene.
- The connected Godot editor may still show stale main-scene state until it reloads project settings.
- The Sandbox main menu buttons were being blocked by the visible `MultiplayerChat` root `Control`, which sat above `Menu` in the scene tree and intercepted mouse input even while its child widgets were hidden.
- `level/scripts/level.gd` now hides `MultiplayerChat` itself until chat is opened, instead of leaving an invisible overlay active over the menu.

## Current Unknowns

- Godot MCP connectivity has been unstable across sessions and restarts.
- Live in-editor verification of the current Terrain3D setup is still needed.
- It is not yet confirmed that the player spawn location lands directly on a valid Terrain3D surface in `Sandbox.tscn`.

## Current Risks

- Spawn logic is currently a fixed scene anchor tied to the chair/flight pad area, which may not generalize cleanly between `Mainland.tscn` and `Sandbox.tscn`.
- Terrain3D runtime/editor behavior may differ from on-disk scene state if the editor has unsaved or stale state.
- Generated AI context files from `codebase-md` are low quality for this repo and should not be trusted as the primary source of truth.

## Working Assumptions

- `Sandbox.tscn` is the current project main scene in `project.godot`.
- `Sandbox.tscn` is the current Terrain3D experimentation scene.
- The repo-local `docs/ai` files are now the preferred persistent context system for future sessions.

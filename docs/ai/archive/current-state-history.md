# Current State Archive

This file preserves older high-detail current-state notes that were useful during active implementation but were too long for fast session recovery.

## Archived On

- 2026-04-24

## Source

- Previous contents of `docs/ai/current-state.md` before it was compressed back to short operational truth.

## Archived Notes

- `AGENTS.md` was upgraded to define `Neo` as the persistent repo-based engineering agent with explicit execution, memory write-back, and Git hygiene loops.
- The player collision shape in `level/scenes/player.tscn` was re-enabled after it was found disabled.
- `level/scenes/Sandbox.tscn` was updated to use Terrain3D data from `res://terrain_data`.
- `terrain_data` now contains seeded Terrain3D region files and `assets.tres`.
- The temporary diagnostic `CSGBox3D` floor added during collision debugging was removed after Terrain3D wiring was added.
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
- `res://Playground.tscn` is the active local character sandbox for Manny + pistol testing.
- `res://level/scenes/Sandbox.tscn` remains the project main scene and still exports `res://level/scenes/player.tscn` as its multiplayer `player_scene`.
- `res://level/scenes/lyrasandbox.tscn` currently exports `res://level/scenes/lyra_player_clean_backup.tscn`, not `res://level/scenes/lyra_player_clean.tscn`.
- `character_body_3d.gd` now drives pistol recoil in code and spawns a lightweight scripted projectile from `UAL1_Standard/Armature/Skeleton3D/RightHand/FAB converted/Muzzle`.
- `Bachtavious.tscn` now contains the saved `Muzzle` marker under the held pistol so projectile spawn can be adjusted in the editor without changing code.
- The projectile is now a real editable scene at `res://simple_projectile.tscn` instead of a code-only `Area3D`, so its mesh/material can be replaced in the editor.
- `Playground.tscn` now uses a Sandbox-style camera rig split with `SpringArmOffset/SpringArm3D/Camera3D`, and `character_body_3d.gd` rotates the camera pivot separately from the Manny body for smoother movement.
- `Playground.tscn` now has a first-pass Lyra-style shooter setup: an over-the-shoulder camera offset and a centered `CanvasLayer` reticle, with `character_body_3d.gd` rotating player/camera yaw together instead of using free orbit around the character.
- The preferred workflow is shifting toward NotebookLM research first, then distilling findings into the Obsidian wiki before implementing nontrivial gameplay systems.
- A dedicated NotebookLM notebook for Godot NPC research now exists at `BanditandTavious Godot AI Systems`, and its first distilled output is captured in `docs/wiki/ai_systems.md`.
- The research workflow had drifted toward standalone wiki report pages; the intended direction is a linked Obsidian second brain where research updates domain pages, cross-links, and memory rather than stopping at isolated summaries.
- Added `res://level/scenes/BanditAI.tscn` as a new AI sandbox scene with a saved fixed camera, directional light, collision-enabled floor, and three autonomous capsule actors:
  - `EnemyNPC`
  - `FriendlyNPC`
  - `VillagerNPC`
- `res://level/scripts/bandit_ai_level.gd` configures the sandbox scene, and `res://level/scripts/bandit_ai_actor.gd` drives the shared placeholder AI behavior.
- The earlier black-screen version of the AI sandbox was preserved as `res://level/scenes/BanditAI_prev_black.tscn`; `BanditAI.tscn` was rebuilt from scratch so camera/light defaults are baked into the saved scene instead of depending only on `_ready()`.
- `BanditAI.tscn` now also stores each actor's role/speed/range/color directly in the scene, so behavior does not depend only on runtime root-script assignment.
- `BanditAI.tscn` now includes `AIActivityLogger` using `res://level/scripts/bandit_ai_activity_logger.gd`, which records periodic actor snapshots to `user://bandit_ai_activity.jsonl`.
- Added `tools/ai_activity_to_sqlite.py` for offline export into SQLite (`logs/bandit_ai_activity.db`) with `actor_samples` and `actor_transitions` tables for training workflows.
- Added wiki page `docs/wiki/ai_training.md` documenting the full logging -> SQLite pipeline and first trainable target (villager flee policy).
- Added clean Lyra multiplayer runtime scenes:
  - `res://level/scenes/lyra_player_clean.tscn`
  - `res://level/scenes/lyra_visual.tscn`
  - `res://level/scripts/lyra_body.gd`
- `lyra_player_clean.tscn` is a standalone `CharacterBody3D` player scene with no `3DGodotRobot` subtree; it keeps the existing camera/chat/multiplayer contract and now instances `res://Bachtavious.tscn` directly as the runtime `_body`.
- `lyra_body.gd` now targets the actual imported Lyra locomotion clips (`Idle`, `Walk`, `Sprint`, `Jump`) instead of assuming the Godot robot animation names.
- `lyra_player_clean.tscn` now replicates `Bachtavious/AnimationPlayer:current_animation` through `MultiplayerSynchronizer`, so the networked animation path matches the direct runtime body scene.
- `lyra_body.gd` now rotates the imported `Armature` child instead of the whole preview scene root, so `Bachtavious.tscn` can be used directly without spinning its preview light and camera.
- `lyra_player_clean.tscn` now uses `res://level/scripts/bachtavious_multiplayer_player.gd` as its root controller; that script is a multiplayer-safe merge of `character_body_3d.gd` mechanics with the authority/chat hooks required by `level.gd`.
- `lyra_player_clean.tscn` was also reset to match the proven `Playground.tscn` body/camera layout more closely:
  - direct `Bachtavious` scene instance with identity transform
  - `SpringArmOffset` at `Vector3(0, 1.8, 0)`
  - `SpringArm3D.spring_length = 2.5`
  - `Camera3D` local offset `(0.6, 0.2, 0)`
- The new multiplayer Bachtavious controller removes the preview-only `WorldEnvironment`, `DirectionalLight3D`, and `Camera3D` nodes from the instanced `Bachtavious.tscn` at runtime so multiplayer players do not carry extra scene-preview nodes.
- The project currently has parallel player/runtime paths: the stock `player.gd` path still drives `Sandbox.tscn`, while the Bachtavious/Lyra controller path exists as an alternate sandbox/runtime candidate.
- The Lyra clean player FSM now includes dedicated `Vault` and `Slide` states (`player_vault.gd`, `player_slide.gd`) and uses scanner-ray vault detection via `find_vault_target()` instead of direct tweening from `_check_parkour()`.
- `player_wall_run.gd` now locks a wall-run animation through `get_wall_run_animation()` with runtime fallback resolution if the exact parkour clip name differs.
- `lyra_player_clean.tscn` now instances `res://Lyra.tscn` as its visual body resource (while retaining the local node name/path contract used by multiplayer replication and controller exports).
- Vault/mantle landing in `bachtavious_multiplayer_player.gd` now computes target origin height from an origin-to-floor probe (`_get_origin_to_floor_offset`) instead of using raw ledge Y; this is intended to prevent hover-after-climb caused by root/capsule offset mismatch.
- `player_vault.gd` now performs a two-phase tween followed by a post-tween grounding pass (downward ray correction + `apply_floor_snap()` + fallback downward `move_and_slide`) and `lyra_player_clean.tscn` now sets `floor_snap_length = 0.3`.
- Vault state now supports root-motion-driven traversal through a runtime `AnimationTree` (`start_vault_root_motion` / `consume_vault_root_motion`) and keeps tween path as fallback; ledge acceptance now includes head-clearance ray checks and temporary capsule height reduction during climb.
- Vault now includes root-motion stall fallback in `player_vault.gd`: if root-motion clip displacement is near-zero while still far from the target, vault automatically falls back to tween traversal instead of hanging at the wall.
- Vault clip selection now prioritizes non-`_RM` variants and only enables root-motion mode for selected `*_RM` clips; on root-motion stall it forces a non-root traversal clip before tween fallback.
- Vault obstacle traversal candidates were changed to non-`_RM` climb clips (`ClimbUp_1m` first, then `Jump_Start/Jump`) to eliminate capsule/mesh desync while root-motion clip compatibility is unresolved.
- `player_vault.gd` now runs as fully procedural capsule-driven traversal (root-motion path removed for vault) so debug collision stays coupled to mesh during climb; post-vault collision mask and collision layer are both restored.
- Vault lifecycle was hardened in `player_vault.gd`: `_finish_vault()` is now single-fire guarded, any active tween is killed on early finish and inside `_finish_vault()`, and vault movement uses only physics velocity (no transform tween movement) to avoid callback/state races.
- Scanner ranges in `lyra_player_clean.tscn` were increased (`ForwardRay`/`HeadRay` from `-1.0` to `-1.4`, `LedgeRay` from `-1.5` to `-2.2`) to better match larger vault obstacles in `lyrasandbox.tscn`.
- Vault target validation now enforces obstacle compatibility bands from character height (vault vs mantle ratios) and ledge-top normal (`LEDGE_MIN_NORMAL_Y`) to avoid triggering climb on invalid obstacle geometry.
- Added a repeatable Karpathy-style research loop path for headless experimentation:
  - `tools/run_research_cycle.ps1` now orchestrates multi-cycle headless runs of `TrainingGround.tscn`.
  - `tools/summarize_experiment.py` now analyzes `user://evolution_log.jsonl`, flags stagnation/regression gaps, and writes `user://evolution_suggestions.json` for next-cycle coach overrides.
  - `training_episode_manager.gd` now accepts CLI overrides (`--episodes`, `--duration`, `--seed`) for automation control.
  - Added `docs/wiki/research_loop.md` and linked it from wiki index/log.

## Archived Unknowns And Risks

- Godot MCP connectivity has been unstable across sessions and restarts.
- Godot can retain stale editor state for `res://level/scenes/lyra_player.tscn` even when the on-disk `.tscn` has been replaced; the clean runtime path is `res://level/scenes/lyra_player_clean.tscn`.
- Godot MCP scene reads can also retain stale Lyra hierarchy after direct `.tscn` edits even when the serialized file on disk is correct, so `read_file` should be treated as the source of truth until the editor reloads the scene.
- `read_scene` for `lyra_player_clean.tscn` may still report the older `player.gd`/`lyra_body.gd` wrapper layout even though the serialized file now points to `bachtavious_multiplayer_player.gd`; the editor likely needs a scene reload to flush that cache.
- Live in-editor verification of the current Terrain3D setup is still needed.
- It is not yet confirmed that the player spawn location lands directly on a valid Terrain3D surface in `Sandbox.tscn`.
- Spawn logic is currently a fixed scene anchor tied to the chair/flight pad area, which may not generalize cleanly between `Mainland.tscn` and `Sandbox.tscn`.
- Documentation and scene wiring can drift: earlier notes claimed `lyra_player_clean.tscn` was active in `lyrasandbox.tscn`, but the serialized scene currently points to `lyra_player_clean_backup.tscn`.
- Terrain3D runtime/editor behavior may differ from on-disk scene state if the editor has unsaved or stale state.
- Generated AI context files from `codebase-md` are low quality for this repo and should not be trusted as the primary source of truth.
- A temporary identity conflict was introduced when `GEMINI.md` defined `Morpheus` as a separate project brain. The repo identity has been consolidated back to `Neo`.
- If research is added without being woven into existing wiki pages and memory files, the vault will behave like a report archive instead of a second brain.

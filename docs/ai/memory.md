# AI Memory

Related:
- [[current-state|Current State]]
- [[ai_masterplan|AI Masterplan]]
- [[neo_goal_sheet|Neo Goal Sheet]]
- [[lessons|Lessons]]
- [[session-notes|Session Notes]]
- [[../wiki/ai_systems|AI Systems]]
- [[../wiki/persistent_sandbox_ai|Persistent Sandbox AI Master Plan]]
- [[../wiki/life_system|Life System]]
- [[../wiki/destruction|Destruction]]
- [[../wiki/index|Wiki Index]]

## Project

- Name: `BanditandTavious`
- Engine: Godot 4.5.1
- Project type: 3D multiplayer prototype built from a Godot multiplayer template and extended with room-based multiplayer and chat features.
- Persistent repo agent identity: `Neo` (defined in `AGENTS.md`) as the long-term engineering agent contract.
- Gemini, Codex, and other assistants should be treated as tools/operators acting on behalf of `Neo`, not as separate repo personas.

## Important Scenes

- Main project scene in `project.godot`: `res://level/scenes/Sandbox.tscn`
- `Sandbox.tscn` is both the current project main scene and the active Terrain3D/multiplayer debugging scene.
- `Sandbox.tscn` currently exports `res://level/scenes/player.tscn` as `player_scene`, so the stock multiplayer player path is still the active project runtime.
- Player scene: `res://level/scenes/player.tscn`
- Quaternius test level: `res://level/scenes/quaternius_test_level.tscn`
- Quaternius test player: `res://level/scenes/quaternius_test_player.tscn`
- Playable Quaternius mannequin wrapper: `res://assets/animations/quaternius/Unreal-Godot/GodotManny.tscn`
- Fresh Manny flat-ground test level: `res://level/scenes/godot_manny_test_level.tscn`
- Fresh Manny flat-ground player scene: `res://level/scenes/godot_manny_player.tscn`
- Current Manny/pistol sandbox scene: `res://Playground.tscn`
- Lyra multiplayer sandbox scene: `res://level/scenes/lyrasandbox.tscn`
- Current concrete weapon pickup scenes: `res://level/scenes/weapons/PistolPickup.tscn` and `res://level/scenes/weapons/RiflePickup.tscn`
- Generic configurable weapon pickup scene: `res://level/scenes/weapons/WeaponPickup.tscn`
- Weapon alignment calibration scene: `res://level/scenes/weapons/WeaponCalibration.tscn`
- Destruction verification scene: `res://level/scenes/DestructibleSphereTest.tscn`
- Reusable destruction benchmark scene: `res://level/scenes/DestructionBenchmark.tscn`
- New decoupled animation system template: `res://BanditAnimationSystem.tscn`
- AI sandbox scene: `res://level/scenes/BanditAI.tscn`
- Performance benchmarking scene: `res://level/scenes/PerformanceStressTest.tscn`
- Vehicle prototype scenes: `res://level/scenes/vehicles/BoxCarPropeller.tscn` and `res://level/scenes/vehicles/BoxCarPropellerTest.tscn`

## Important Scripts

- `level/scripts/level.gd`: scene-level multiplayer flow, spawning, menu, chat
- `level/scripts/player.gd`: movement, gravity, jump, camera authority, respawn, shooting
- `level/scripts/lyra_body.gd`: Lyra visual-body adapter used by the clean multiplayer Lyra player scenes
- `level/scripts/network.gd`: multiplayer networking support
- `level/scripts/terrain_dig.gd`: Terrain3D interaction helper
- `level/scripts/quaternius_test_player.gd`: lightweight third-person spherical-gravity movement and animation test harness for the Quaternius mannequin import
- `level/scripts/godot_manny_player.gd`: flat-ground third-person Manny controller that instantiates the imported Quaternius model at runtime
- `character_body_3d.gd`: local `Animations.tscn` controller for Manny movement, aiming, recoil, and projectile spawning
- `level/scripts/states/player_vault.gd`: scanner-driven vault/mantle traversal state that tweens player position over obstacles
- `level/scripts/states/player_slide.gd`: momentum-based crouch slide traversal state
- `simple_projectile.tscn` + `simple_projectile.gd`: editable bullet scene used by `character_body_3d.gd`
- `level/scripts/weapons/weapon_inventory_component.gd`: player-owned component for equipping/dropping `WeaponResource` data through a resolved `WeaponMaster`.
- `level/scripts/weapons/weapon_pickup.gd`: `Area3D` pickup logic that equips a `WeaponInventoryComponent` on body overlap or `interact(player)`.
- `level/scripts/weapons/weapon_master.gd`: held-weapon runtime/editor container that instantiates weapon visuals and applies per-resource visual/muzzle offsets.
- `level/scripts/weapons/weapon_resource.gd`: weapon data resource with visual scene, hand alignment offsets, muzzle offsets, stats, and effects.
- `level/scripts/weapons/weapon_alignment_calibration.gd`: editor/runtime helper for previewing one `WeaponResource` against Bachtavious pistol animations in `WeaponCalibration.tscn`.
- `level/scripts/weapons/weapon_pickup_test.gd` and `weapon_pickup_lyra_bridge_test.gd`: headless verification scenes for generic and Lyra/Bachtavious pickup behavior.
- `level/scripts/destructible_sphere_test.gd`: self-testing destruction harness that launches a projectile into `DestructibleSphere.tscn`
- `level/scripts/destruction_benchmark.gd`: reusable projectile-vs-target destruction benchmark that instances a destructible scene and logs standardized headless metrics
- `level/scripts/bandit_ai_level.gd`: scene-level setup for the `BanditAI` sandbox
- `level/scripts/bandit_ai_actor.gd`: shared placeholder AI actor logic for enemy, friendly, and villager capsules
- `level/scripts/bandit_ai_activity_logger.gd`: JSONL activity logger for `BanditAI` that writes snapshots to `user://bandit_ai_activity.jsonl`
- `level/scripts/lyra_ai_phase1_manager.gd`: runtime manager for the first Lyra sandbox AI slice, spawning capsule gatherers, a real sandbox navigation region, optional fallback test pad, food/water/resource targets, waypoint patrol markers, reservations, and metrics.
- `level/scripts/lyra_ai_actor.gd`: capsule gatherer Utility AI + FSM controller for food/water/resource collection, weapon pickup, combat, and scout waypoint exploration.
- `level/scripts/lyra_ai_target.gd`, `lyra_ai_waypoint.gd`, `lyra_ai_task_board.gd`, and `lyra_ai_metrics.gd`: target metadata, waypoint markers, target reservation/lookup, and JSONL metrics support for the Lyra AI prototype.
- `level/scripts/lyra_ai_memory_store.gd`: persistent Lyra AI memory store that writes actor summaries to `user://lyra_ai_memory.json` and event history to `user://lyra_ai_memory_events.jsonl`, then restores remembered actor summaries on the next `lyrasandbox` launch.
- `level/scripts/lyra_ai_phase1_manager.gd` also supports loop CLI options `--ai-test`, `--duration`, `--ai-count`, `--seed`, `--ai-test-pad`, `--ai-local-nav`, and `--metrics-path`.
- `level/scripts/performance_monitor.gd`: Global Autoload HUD (**F9**) and CSV logger for runtime performance benchmarking.
- `level/scripts/performance_stress_test.gd`: Controller for spawning AI and destructible batches in the performance sandbox.
- `level/scripts/vehicles/box_car_propeller.gd`: code-driven prototype vehicle movement plus wheel, steering, and rear-propeller visual animation.
- `level/scripts/vehicles/box_car_propeller_test.gd`: preview and headless motion verification harness for the box-car propeller prototype.
- `tools/ai_activity_to_sqlite.py`: offline converter from `bandit_ai_activity.jsonl` to SQLite database `logs/bandit_ai_activity.db`
- `tools/run_research_cycle.ps1`: headless multi-cycle experiment runner for TrainingGround-style research loops
- `tools/summarize_experiment.py`: evolution log analyzer that emits cycle summaries, research-gap flags, and coach suggestions

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
- Verification gate for gameplay/code changes before giving a green light:
  1. run the target scene in Godot
  2. check runtime logs/errors via MCP (`get_console_log` / `get_errors`)
  3. capture at least one screenshot as evidence of expected in-game state
  4. stop the running session/process cleanly before reporting completion
- For headless Godot CLI verification on this machine, pass an explicit `--log-file` under repo `logs/` or the mono executable can crash before scene execution while opening its default `user://logs/...` target.

## Memory Workflow

- Agents must read the `docs/ai/*.md` files before substantial work.
- Agents should write back only durable knowledge, not noisy transcripts.
- `Neo` should follow a repeatable loop: load context -> execute/verify -> write back durable knowledge -> keep Git clean -> capture improvement rules.
- `Neo` also has an optional operator-triggered Loop Mode documented in `docs/ai/neo_loop.md` and powered by `tools/neo_check.ps1` / `tools/neo_loop.ps1`; it must not run automatically on every session.
- `docs/ai/neo_goal_sheet.md` is the concise operator-facing tracker for staying on goal; it summarizes the north star, current track, completed milestones, next three goals, drift risks, and required proof.
- The target long-term agent design for `Neo` is documented in `docs/wiki/neo_architecture.md`; the current repo has identity, memory, loop, research components, initial canonical `docs/ai/neo_state.json`, ranked `docs/ai/neo_backlog.md`, replayable loop artifacts under `logs/neo_loops/`, `neo_check.ps1` milestone evidence summaries, named `PASS`/`WARN`/`FAIL` gate profiles, and manifest-backed visual evidence registration under `logs/visual_evidence/`, but still lacks richer per-profile thresholds and automatic promotion tooling.
- For visible Neo claims, use `tools/register_neo_visual_evidence.ps1` to copy a real screenshot/video into `logs/visual_evidence/YYYYMMDD_HHMMSS_<type>/` with `manifest.json`. The `lyra_visual` gate should fail until a manifest-backed capture proves the visual claim.
- `tools/capture_lyra_ai_visual.gd` is the reliable visual-capture path for generic Lyra AI actor visibility. It avoids OS screenshots of the menu/player camera by placing a temporary camera on a runtime `lyra_ai_actor` and saving a viewport PNG for registration.
- `docs/raw/masterplans/master_plan.pdf` establishes the long-term AI north star as a persistent sandbox: Godot plus SQLite first, durable world state and NPC memory before model training, LLMs only on slow planning/reflection/dialogue/research loops, and verified before/after evidence for accepted AI improvements. The distilled wiki page is `docs/wiki/persistent_sandbox_ai.md`.
- For nontrivial systems and architecture changes, prefer a research-first workflow: search NotebookLM, distill the result into `docs/wiki/`, then implement against that synthesized guidance.
- Treat `docs/wiki/` as the durable system-overview layer for patterns the team is actively learning or refining; once a workflow repeatedly succeeds, it should be captured there as a reusable pattern or future skill candidate.
- NotebookLM and other research should be compiled into linked Obsidian knowledge, not left as isolated report pages. Update existing domain pages when possible, add cross-links, and write back the parts that change project direction or workflow.
- For iterative AI/system research, prefer scripted multi-cycle headless runs plus automatic summary artifacts over ad-hoc single runs.
- Shared cross-agent skills now use `skills/` as the canonical repo location. Tool-specific skill folders such as `.gemini/skills/` are mirrors or creation points that should be synced back into `skills/` via `tools/sync_shared_skills.ps1`.
- The first Lyra AI prototype is wired into `level/scenes/lyrasandbox.tscn` through `LyraAIPrototype`; it now defaults to a real sandbox nav zone near the playable props and keeps the old `AITestPad` only as an opt-in `--ai-test-pad` fallback.
- The broad Lyra AI nav experiment uses 6 role-biased actors (`forager`, `hauler`, `scout`) and target cooldowns after stuck events, but current headless metrics show blocked long routes; do not treat broad sandbox navigation as solved until a real nav bake or waypoint/corridor graph replaces hand-authored rectangles.
- The Lyra AI prototype now has a larger generated corridor-style sandbox nav mesh, runtime-corrected food/water/resource target positions, reachable runtime weapon pickups, and actor-side `WeaponInventoryComponent` support so capsule AI can pick up `WeaponPickup` weapons during headless runs.
- Runtime AI weapon pickups should be placed inside nav-cell interiors, not directly on generated nav quad boundaries. The April 25, 2026 loop pass found `AI_PistolPickup_02` at `(27, 22)` caused a repeat stuck cluster; moving it to `(25, 20)` removed weapon-target stuck events in verification.
- The Lyra AI shooting milestone uses a runtime `AI_TargetDummy_01` combat target, a `combat` utility goal for armed AI, `WeaponMaster.fire()` for cooldown/effects, and raycast hit resolution that logs `shot_fired` metrics.
- The first bigger-navigation pass expanded the generated nav to a 6x6 grid and added a second combat dummy in the east corridor. A combat seek-distance filter prevents actors from accepting far combat targets that route through blocked sandbox geometry; this kept a 10-seed expanded-nav batch at 0 stuck events.
- The concrete Lyra waypoint-navigation pass adds runtime `AINavWaypoints`, `lyra_ai_waypoint.gd`, an `explore` task-board goal, scout lane routes, `route_visit` metrics, and parser route summaries. Final 5 fixed 30-second seeds produced 30 route visits, 4 distinct waypoint names per run (`WP_CentralMarket`, `WP_EastOuter`, `WP_NorthEast`, `WP_SpawnLane`), 20 weapon pickups, 96 shots, 95 hits, and 0 stuck events.
- The first visible Lyra building milestone adds runtime `AIBuildSites`, `lyra_ai_build_site.gd`, a visible `BuildSite_Barricade_01` that progresses from foundation marker to completed planks after two resource deliveries, a `build` utility goal for resource-carrying actors, and `build_started` / `build_resource_delivered` / `build_completed` metrics. A 50-run 18-second batch produced 49/50 completed builds before tuning; increasing `build_distance` to `4.5` fixed the failing seed, and a post-fix 10-seed tail batch produced 10/10 completed builds, 0 stuck events, 40 weapon pickups, 97/97 hits, and 31 route visits.
- The first Lyra AI persistent-memory slice is implemented. `AIMemoryStore` is created by `lyra_ai_phase1_manager.gd`, records AI metrics into `user://lyra_ai_memory.json`, and restores actor summaries on restart. Loop evidence in `logs/neo_loops/20260426_114246_loop_1/` proves run 1 loaded 0 actor memories and run 2 loaded 6 actor memories plus emitted 6 `ai_memory_restored` events.
- Current Lyra memory persistence is telemetry/restoration only. It records remembered goals, interactions, weapon pickups, shots, route visits, build state, and stuck counts, but it does not yet alter utility scoring or actor behavior from memory.
- `docs/wiki/life_system.md` is the current design proposal for the next shared gameplay spine: a reusable `LifeComponent` for health, damage, downed/death, recovery, revive, respawn, metrics, and memory events across Lyra AI actors and players.
- For repeated Lyra AI headless loops, pass a unique `--metrics-path res://logs/...jsonl` or rely on `lyra_ai_metrics.gd` removing the previous metrics file before opening it; reusing one fixed JSONL path caused stale null/trailing bytes in batch runs.
- The active Lyra weapon pickup path is now `WeaponPickup.tscn` -> `weapon_pickup.gd` -> `WeaponInventoryComponent` -> `WeaponMaster`. Use `PistolPickup.tscn` or `RiflePickup.tscn` for placed level pickups; `WeaponWorldItem.tscn` and `SilverWeaponWorldItem.tscn` are legacy compatibility scenes.
- In the Lyra/Bachtavious path, `E` interacts with nearby pickups and `G` drops the current weapon. `PistolPickup.tscn`, `RiflePickup.tscn`, and dropped pickups use `auto_pickup = false`; `consume_on_pickup` only decides whether the pickup disappears after a successful equip.
- Do not place raw weapon visual scenes such as `A3500X_silver_rigged.glb` or `SilverRifle.tscn` as interactable level objects. They look like guns but do not provide `weapon_pickups` group membership or `interact()`.
- Weapon alignment rule: tune the character hand socket once by moving `WeaponMaster`; tune every individual gun in its `WeaponResource` using `position_offset`, `rotation_offset`, `scale_offset`, `muzzle_position_offset`, and `muzzle_rotation_offset`.

## AI Research Facts

- NotebookLM is now configured for Codex through the `nlm` toolchain; the older `notebooklm` CLI should not be treated as the primary integration path on this machine.
- The dedicated NotebookLM notebook for Godot NPC research is `BanditandTavious Godot AI Systems`.
- The preferred Godot AI direction for this project is documented in [[../wiki/ai_systems|AI Systems]].

## Quaternius Character Facts

- `assets/animations/quaternius/Unreal-Godot/GodotManny.tscn` is no longer only a visual `Node3D`; it is now a playable `CharacterBody3D` wrapper around `UAL1_Standard.glb`.
- The wrapper reuses `level/scripts/quaternius_test_player.gd` with `Model`, `CollisionShape3D`, and `SpringArmOffset/SpringArm3D/Camera3D` nodes that match the script's expected paths.
- `level/scenes/quaternius_test_level.tscn` now instantiates `GodotManny.tscn` for direct testing.
- The fresh test path is `level/scenes/godot_manny_test_level.tscn`, which uses a flat `CSGBox3D` floor plus `godot_manny_test_level.gd` to spawn `godot_manny_player.tscn`.
- `godot_manny_player.gd` avoids the older spherical-gravity spawn/orientation logic and is the preferred script for simple floor-based Manny testing.
- `level/scenes/godot_manny_test_level.tscn` now directly instances `godot_manny_player.tscn` as a visible `Player` child in the editor.
- `level/scenes/lyrasandbox.tscn` currently exports `res://level/scenes/lyra_player_clean.tscn` as `player_scene`; treat it as the active Lyra/Bachtavious sandbox branch, not the main project runtime.
- `level/scenes/lyra_player_clean.tscn` is the clean Lyra multiplayer runtime player: a standalone `CharacterBody3D` scene with the existing multiplayer/camera/chat contract, `Bachtavious` as the direct `_body`, and no `3DGodotRobot` subtree.
- `res://Bachtavious.tscn` is now the direct visual/runtime body reference for the clean Lyra multiplayer player path; it provides the armature, pistol, muzzle, and top-level `AnimationPlayer`.
- `level/scripts/bachtavious_multiplayer_player.gd` is the current multiplayer Bachtavious controller. It is derived from the working `character_body_3d.gd` path and keeps the spawn/authority/chat methods that `level.gd` expects from multiplayer players.
- `level/scenes/lyra_player.tscn` may still appear in editor memory as an older cached wrapper scene and should not be treated as the source of truth for Lyra runtime testing.
- The direct Lyra multiplayer animation replication path is `Bachtavious/AnimationPlayer:current_animation`.
- `level/scenes/lyra_player_clean.tscn` now mirrors the proven `Playground.tscn` camera/body arrangement more closely than the older multiplayer player path.
- `Playground.tscn` uses `character_body_3d.gd` with Manny instanced from `Bachtavious.tscn`; the held pistol lives under `UAL1_Standard/Armature/Skeleton3D/RightHand/FAB converted`.
- `Bachtavious.tscn` now includes a `Muzzle` marker under the held pistol for editor-adjustable projectile spawn.
- `Playground.tscn` mirrors the Sandbox player camera split by using `SpringArmOffset/SpringArm3D/Camera3D`; `character_body_3d.gd` pans the camera on the spring-arm pivot while rotating the Manny model toward movement with smoothing.
- `Playground.tscn` also has a first-pass Lyra-style setup with an over-the-shoulder camera offset and a simple centered reticle HUD.

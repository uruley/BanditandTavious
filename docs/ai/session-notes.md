# Session Notes

Related:
- [[memory|AI Memory]]
- [[current-state|Current State]]
- [[lessons|Lessons]]
- [[../wiki/index|Wiki Index]]

## Last Significant Session

- Ran an operator-requested 30-loop headless Lyra AI improvement pass:
  - Expanded runtime AI navigation to a larger connected corridor-style sandbox nav mesh.
  - Runtime-corrected persistent food/water/resource target positions and added fourth target variants for each resource type.
  - Added reachable runtime pistol/rifle pickups for AI and gave capsule actors a `WeaponInventoryComponent` plus hidden `WeaponMaster`.
  - Extended the task board so `weapon` goals can reserve/interact with `weapon_pickups`.
  - Added `--seed` and `--metrics-path` loop CLI support and fixed metrics-file cleanup before writing.
  - Baseline 25-second run before the pass: 14 interactions, 0 weapon pickups, 21 stuck events, score `19.6762`.
  - 30 valid 12-second loops after improvements averaged score `104.3337`, 15.8667 interactions, 3.9333 weapon pickups, and 1.3 stuck events.
  - Final 25-second comparison run: 24 interactions, 4 weapon pickups, 5 stuck events, score `185.52`.
- Rebuilt the Lyra/Bachtavious weapon pickup spine:
  - Added `WeaponInventoryComponent` as the player-owned equip/drop component.
  - Added `WeaponPickup.tscn` / `weapon_pickup.gd` as the new `Area3D` pickup source of truth.
  - Added concrete placed pickup scenes `PistolPickup.tscn` and `RiflePickup.tscn`.
  - Bridged `bachtavious_multiplayer_player.gd` to the component while keeping legacy fallback paths.
  - Added isolated generic and Lyra bridge tests, both passing headless.
  - Replaced the old broken placed weapon world items in `lyrasandbox.tscn` with the new pickup scenes.
  - Split pickup behavior into `auto_pickup` and `consume_on_pickup`; placed pistol/rifle pickups now require `E`, and `G` drops the current weapon as a non-auto pickup.
  - Removed raw non-pickup gun visual nodes from `lyrasandbox.tscn`, enlarged the pickup collision sphere, and added a nearby-pickup fallback for `E` interaction.
  - Added the weapon alignment workflow: per-resource visual scale/position/rotation and muzzle offsets, editor-refreshing `WeaponMaster`, copied the proven Bachtavious hand socket into `lyra_player_clean.tscn`, and wired `WeaponCalibration.tscn` for pistol animation preview.
- Implemented the first `lyrasandbox` AI vertical slice:
  - Added `LyraAIPrototype` to `level/scenes/lyrasandbox.tscn`.
  - Added capsule gatherers with utility goal selection for food/water/resource needs.
  - Added runtime food/water/resource target markers, a reservation task board, an isolated AI test pad, and JSONL metrics.
  - Verified headless with explicit `--log-file`; the run produced 4 active AI actors, 16 successful interactions, 0 stuck events, and a parser score of `118.0888`.
- Upgraded the Lyra AI slice from direct movement to navigation-aware prototype movement:
  - Added persistent editor-visible target nodes under `LyraAIPrototype/Targets`.
  - Added `NavigationAgent3D` movement for capsule gatherers.
  - Added a runtime `NavigationRegion3D` over the isolated AI test pad.
  - Added debug labels showing goal, target, hunger, thirst, and resource count.
  - Verified headless with explicit `--log-file`; the run produced 4 active AI actors, 14 successful interactions, 0 stuck events, and a parser score of `100.2306`.
- Moved the Lyra AI slice off the isolated pad by default:
  - `LyraAIPrototype` now creates `AISandboxNavigationRegion` in the real sandbox play area.
  - Persistent targets were moved near the playable chair/prop area instead of negative-X test-pad space.
  - The old `AITestPad` is now opt-in with `--ai-test-pad`.
  - Verified headless with explicit `--log-file`; the run produced 4 active AI actors, 12 successful interactions, 0 stuck events, and a parser score of `80.2057`.
- Expanded the Lyra AI slice into a broad-navigation experiment:
  - Increased the scene to 6 capsule actors with `forager`, `hauler`, and `scout` roles.
  - Spread food/water/resource targets farther across the sandbox.
  - Added target cooldowns after stuck events so actors stop immediately retrying blocked routes.
  - Verified headless with explicit `--log-file`; the run produced 6 active AI actors, 4 successful interactions, 10 stuck events, and a parser score of `-41.2874`, so this is a `PARTIAL` result rather than a completed navigation upgrade.
- Upgraded the shared `godot-ai` skill into a Lyra sandbox AI roadmap:
  - Phase 1 starts with capsule NPCs, food/water/resource targets, utility goal choice, FSM execution, reservations, and JSONL metrics.
  - Later phases cover blackboard/task-board coordination, weapons/team roles, vehicles/aircraft, and Loop Mode plus OpenRouter as an offline tuning coach.
  - Added `skills/godot-ai/scripts/parse_ai_metrics.py` to summarize AI JSONL metric logs and produce a simple loop score.
- Added a new destruction test asset path:
  - Authored and exported `res://assets/fractured_sphere.glb` through the Blender fracture bridge.
  - Added `level/scenes/DestructibleSphere.tscn` as a replacer-style destructible sphere using `level/scripts/destructible.gd`.
  - Added `level/scenes/DestructionBenchmark.tscn` plus `level/scripts/destruction_benchmark.gd` as a reusable projectile-vs-target benchmark scene/script for destructible assets.
  - Rewired `level/scenes/DestructibleSphereTest.tscn` to use the generic benchmark path as the concrete example configuration for the sphere asset.
  - Verified serialized scene wiring in the editor and confirmed the scene opens cleanly in Godot.
  - Identified the headless blocker as Godot mono's default CLI log destination, not the destructible scene itself.
  - Confirmed headless runs work when passing an explicit repo-local `--log-file`.
  - Instrumented the generic benchmark to log machine-readable destruction metrics including shard count, spread, settle behavior, and pre/post impact frame deltas.
- Added a repo-owned shared skills workflow:
  - `skills/` is now the canonical source for cross-agent reusable skills.
  - Added `tools/sync_shared_skills.ps1` to import from `.gemini/skills/`, export back to Gemini, and install shared skills into Codex's user skill directory.
  - Added a canonical `skills/godot-destructibles/` skill with a stronger checklist-oriented destruction pipeline and verification contract.
- Upgraded `AGENTS.md` to establish `Neo` as the persistent repo-based engineering agent with explicit context loading, verification, write-back, and Git-cleanliness loops.
- Cleaned the repo identity/documentation layer so `Neo` remains the single repo agent, `GEMINI.md` is operator guidance rather than a competing persona, `current-state.md` is short again, and older state detail now lives in `docs/ai/archive/current-state-history.md`.
- Added an explicit optional Loop Mode for `Neo` with goal/scoreboard docs, Windows-friendly PowerShell helpers, and lightweight eval checklists. Loop Mode is operator-triggered only and does not run on normal sessions.
- Investigated why the player was falling through the floor.
- Found the player collision shape in `player.tscn` had been disabled and re-enabled it.
- Determined earlier floor checks were misleading because the active debugging scene differed from the originally inspected scene.
- Identified that `Sandbox.tscn` relied on `Terrain3D` rather than a standard floor node.
- Set up repo-local Terrain3D data wiring for `Sandbox.tscn`.
- Added a repo-local AI memory system under `docs/ai` and updated `AGENTS.md` to enforce the read/write loop.
- Implemented parkour FSM expansion for `lyra_player_clean.tscn`:
  - Added `Vault` state (`level/scripts/states/player_vault.gd`) with two-phase tween traversal over scanner-detected obstacles.
  - Added `Slide` state (`level/scripts/states/player_slide.gd`) with momentum decay and slope assist.
  - Updated `Idle`/`Run` to transition to `Vault` using `find_vault_target()` from `bachtavious_multiplayer_player.gd`.
  - Updated `WallRun` to lock a resolved wall-run animation via `get_wall_run_animation()` with fallback clip matching.
- Used Godot MCP to inspect live `lyrasandbox.tscn` hurdle objects and scanner setup:
  - `CSGMesh3D3`/`CSGMesh3D4` are large collision-enabled CSG hurdles.
  - Scanner rays in `lyra_player_clean.tscn` were still short-range.
- Added a vault root-motion stall guard in `player_vault.gd` so climb falls back to tween when root-motion displacement stalls near the wall.
- Increased scanner cast ranges in `lyra_player_clean.tscn` (`ForwardRay`, `HeadRay`, `LedgeRay`) to better match hurdle size.
- Added an automated research loop path for headless experiment batches:
  - `tools/run_research_cycle.ps1` runs repeated headless `TrainingGround.tscn` cycles with per-cycle seed/episode overrides.
  - `tools/summarize_experiment.py` summarizes evolution logs, flags stagnation/regression gaps, and writes coach suggestions for the next cycle.
  - `training_episode_manager.gd` now parses `--episodes`, `--duration`, and `--seed` from CLI user args.
  - Added `docs/wiki/research_loop.md` to document the full run/analyze/write-back process.

## Pending Verification From This Session

- Live editor walk-up test for the new Lyra pickup scenes in `level/scenes/lyrasandbox.tscn`, with screenshot or recording evidence for `E` pickup and `G` drop.
- Editor calibration pass for `level/data/weapons/pistol.tres` in `WeaponCalibration.tscn`, with a screenshot of alignment against `Pistol_Aim_Neutral`.
- Run `lyrasandbox.tscn` and confirm:
  - wall-run animation chosen by `get_wall_run_animation()` matches desired parkour visual
  - low obstacle vault and high mantle transitions complete and recover into `Run/Idle`
  - slide entry/exit feel and speed values are tuned for gameplay

## Recommended Next Steps

- In Godot, run `level/scenes/lyrasandbox.tscn` as the current scene, walk Bachtavious near `RiflePickup_Ground` or `PistolPickup_Ground`, press `E`, then press `G` to drop. The expected log lines are `WEAPON_PICKUP: equipped Rifle` / `WEAPON_PICKUP: equipped Pistol` and `Dropping weapon...`.
- Open `level/scenes/weapons/WeaponCalibration.tscn`, assign `level/data/weapons/pistol.tres`, and tune the resource offsets until the pistol grip sits correctly in Bachtavious's right hand through `Pistol_Aim_Neutral`, `Pistol_Shoot`, and `Pistol_Reload`.
- After Lyra live pickup is visually confirmed, decide whether the stock main `Sandbox.tscn` / `player.gd` runtime should be migrated to `lyra_player_clean.tscn` or given the same `WeaponInventoryComponent` bridge.
- Replace hand-authored Lyra AI broad-nav rectangles with a real navigation bake or explicit waypoint/corridor graph from sandbox collision geometry.
- Re-establish Godot MCP connectivity and verify the live `Sandbox.tscn` terrain collision setup.
- Confirm the player lands on the Terrain3D surface in runtime.
- If spawn placement is still unreliable, adjust spawn logic to place players based on terrain height rather than a fixed `y = 100.0`.

## Open Questions

- Is the current Terrain3D data layout in `terrain_data` the final intended terrain for the sandbox, or only a bootstrap surface?
- Should `Mainland.tscn` also be migrated to Terrain3D, or remain separate from the sandbox experiment?

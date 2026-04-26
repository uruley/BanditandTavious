# Current State

Related:
- [[memory|AI Memory]]
- [[lessons|Lessons]]
- [[session-notes|Session Notes]]
- [[archive/current-state-history|Current State Archive]]
- [[../wiki/terrain3d|Terrain3D]]
- [[../wiki/multiplayer|Multiplayer]]

## What The Project Is Right Now

- Godot 4.5.1 3D multiplayer prototype with Terrain3D, room-based networking, chat, and parallel sandbox branches for player, AI, parkour, and destruction work.
- `Sandbox.tscn` is the main project scene in `project.godot`.
- The single persistent repo engineering agent identity is `Neo`. Other assistants are operators or tools, not separate project personas.

## What Is Currently Working

- Repo memory architecture is established through `AGENTS.md`, `docs/ai/`, and `docs/wiki/`.
- `docs/ai/ai_masterplan.md` now defines the small-milestone AI path: weapon pickup, shooting, bigger navigation, first building, and tactical combat.
- `docs/raw/masterplans/master_plan.pdf` has been reviewed and distilled into `docs/wiki/persistent_sandbox_ai.md`; the long-term AI north star is now a persistent sandbox with SQLite-backed world state, event logs, NPC memories, relationships, schedules, inventory, world objects, verification evidence, and later training only after clean datasets exist.
- Optional Loop Mode support now exists through `docs/ai/neo_*`, `tools/neo_check.ps1`, and `tools/neo_loop.ps1`, but it is off by default.
- The first Neo kernel upgrade slice is implemented: `docs/ai/neo_state.json` is the canonical machine-readable state file, `docs/ai/neo_backlog.md` separates ranked next work from the active goal, `tools/neo_check.ps1` / `tools/neo_loop.ps1` read and report canonical state, loop evidence is stored under `logs/neo_loops/`, and `neo_check.ps1` now summarizes milestone evidence plus named `PASS`/`WARN`/`FAIL` gate profiles.
- Neo now has a manifest-backed visual evidence path: `tools/register_neo_visual_evidence.ps1` registers screenshots/videos into `logs/visual_evidence/`, and the `lyra_visual` gate fails unless registered live visual evidence exists.
- Neo now has a proven AI-character visual capture path: `tools/capture_lyra_ai_visual.gd` loads `lyrasandbox`, hides the menu, points a camera at a runtime `lyra_ai_actor`, saves a viewport PNG, and the registered evidence at `logs/visual_evidence/20260426_113419_other/manifest.json` makes `tools/neo_check.ps1 -GateProfileOverride lyra_visual` pass.
- A stronger target architecture for `Neo` is now documented in `docs/wiki/neo_architecture.md`; the current system is a good persistent workflow, but not yet a full evidence-driven self-improving agent.
- Shared skill workflow is now repo-owned through `skills/`, with `tools/sync_shared_skills.ps1` available to sync Gemini-created skills back into the canonical repo copy and install shared skills into Codex when needed.
- Main runtime path is still `Sandbox.tscn` -> `level.gd` -> `player.tscn` / `player.gd`.
- Terrain3D data is wired into `Sandbox.tscn` through `res://terrain_data`.
- `Playground.tscn` is available as the local Manny/Bachtavious combat sandbox.
- A reusable destruction test asset now exists through `level/scenes/DestructibleSphere.tscn` and `level/scenes/DestructibleSphereTest.tscn`.
- A reusable destruction benchmark path now exists through `level/scenes/DestructionBenchmark.tscn` and `level/scripts/destruction_benchmark.gd`.
- `BanditAI.tscn` and the AI activity logging/export pipeline are present for research-driven NPC work.
- A new modular, data-driven **Weapon System** is established using `WeaponResource` (.tres) and `WeaponMaster.tscn`, based on the StayAtHomeDev architecture.
- `Playground.tscn` and the `CharacterBody3D` (Manny) are refactored to use this new system.
- Shared `godot-weapon-system` skill is created and now documents the active Modular Weapon System spine, including `WeaponPickup`, `WeaponInventoryComponent`, `WeaponMaster`, `WeaponResource`, Lyra/Bachtavious `E` pickup and `G` drop, legacy-scene warnings, and the calibration workflow.
- `lyrasandbox.tscn` now points at `lyra_player_clean.tscn`, which uses the Bachtavious controller path and should be treated as the active Lyra weapon sandbox.
- The rebuilt weapon pickup/equip spine is implemented for the Lyra/Bachtavious path through `WeaponPickup.tscn`, `WeaponInventoryComponent`, `PistolPickup.tscn`, and `RiflePickup.tscn`. Headless tests prove generic auto-pickup, explicit `E` rifle pickup from nearby range, and `G` weapon drop. Raw non-pickup gun visual nodes were removed from `lyrasandbox.tscn` so visible guns are now the actual pickup scenes.
- Weapon alignment now follows a socket-plus-resource model: `WeaponMaster` under the character hand stores the rig-level socket, while each `WeaponResource` stores visual scale/position/rotation and muzzle offsets. `WeaponCalibration.tscn` is available for tuning pistols against Bachtavious pistol animations.
- `lyrasandbox.tscn` now includes `LyraAIPrototype`, a Phase 1 AI slice with capsule gatherers, persistent food/water/resource target nodes, reservation fallback, `NavigationAgent3D` movement over a larger generated sandbox nav zone, debug labels, JSONL metrics, lightweight roles, target cooldowns after stuck events, runtime AI weapon pickups, and an opt-in fallback test pad.
- A 30-loop headless Lyra AI improvement pass completed on April 25, 2026: 30 valid 12-second loops averaged score `104.3337`, `15.8667` interactions, `3.9333` weapon pickups, and `1.3` stuck events per loop. A final 25-second comparison run produced 24 interactions, 4 weapon pickups, 5 stuck events, and score `185.52`.
- A follow-up 40-loop headless Lyra AI pass on April 25, 2026 found `AI_PistolPickup_02` caused 20 of 54 stuck events. Moving that runtime pickup from the nav boundary at `(27, 22)` to the cell interior at `(25, 20)` removed the weapon stuck cluster in verification; a same-seed 10-loop comparison improved score `98.8507 -> 107.631`, interactions `151 -> 162`, and weapon pickups `35 -> 40`.
- The first Lyra AI shooting milestone is implemented. Armed capsule AI can select a `combat` goal, fire through `WeaponMaster.fire()`, raycast against `AI_TargetDummy_01`, and log `shot_fired` metrics. A 5-seed 18-second headless batch produced 20 weapon pickups, 117 shots, 95 hits, 0 stuck events, and accuracy `0.812`.
- The first bigger-navigation milestone is implemented as an expanded generated nav grid: 6x6 connected cells, far food/water/resource markers, a second combat dummy in the expanded east corridor, AI actor non-collision, and a combat seek-distance filter. A 10-seed 18-second headless batch produced 40 weapon pickups, 131 non-combat interactions, 186 shots, 148 hits, 30 hits on `AI_TargetDummy_02`, and 0 stuck events.
- The concrete waypoint-navigation milestone is now implemented. `lyra_ai_phase1_manager.gd` spawns named `AINavWaypoints`; `lyra_ai_task_board.gd` exposes an `explore` goal; scout actors follow lane-specific waypoint routes and log `route_visit`. A final 5 fixed 30-second sequential batch produced 30 route visits, 4 distinct waypoint names in every run, 20 weapon pickups, 96 shots, 95 hits, and 0 stuck events.
- The first visible building milestone is implemented. `lyra_ai_phase1_manager.gd` spawns `BuildSite_Barricade_01`; `lyra_ai_build_site.gd` renders a foundation/progress marker and completed plank barricade; haulers with resources can select `build` and log build progress metrics. A 50-run 18-second batch produced 49/50 completed builds; after increasing build interaction radius to handle the failing seed, a 10-seed post-fix tail batch produced 10/10 completed builds, 0 stuck events, 40 weapon pickups, 97/97 shots hit, and 31 route visits.
- The first Lyra AI persistent-memory log is implemented and verified. `lyra_ai_memory_store.gd` writes `user://lyra_ai_memory.json` plus JSONL event history, `lyra_ai_metrics.gd` mirrors metrics into the store, and `lyra_ai_actor.gd` emits `ai_memory_restored` when actor summaries are reloaded. Loop artifact `logs/neo_loops/20260426_114246_loop_1/` proves a reset run loaded 0 actor memories and the next restarted run loaded 6 actor memories and restored all 6 gatherers.
- Life-system audit is complete in `docs/wiki/life_system.md`. Current damage/health behavior is fragmented across stock player respawn-on-hit, Bachtavious projectile firing without `take_damage`, Lyra AI actors without health, dummy-only health, and destructible-only health/destroy paths. The proposed next implementation is a shared `LifeComponent`.
- Global Performance HUD (**F9**) and `PerformanceStressTest.tscn` are operational for benchmarking.
- A first code-driven vehicle animation prototype exists at `level/scenes/vehicles/BoxCarPropeller.tscn`, with a test scene at `level/scenes/vehicles/BoxCarPropellerTest.tscn`; it uses visible wheel spin markers, colored runtime materials, and speed/preview-driven wheel and propeller animation.
- A new **Performance Engineering Skill** bundle and optimization wiki are established.
- NotebookLM-to-wiki research workflow is documented and supported by the existing wiki pages and `tools/` scripts.
- Headless Godot verification is usable again when runs pass an explicit repo-local `--log-file`; the default CLI log destination still crashes the mono executable on this machine.

## What Is Currently Broken Or Unconfirmed

- Live verification of Terrain3D collision and spawn placement in `Sandbox.tscn` is still pending.
- Godot MCP/editor state can be stale, especially around Lyra-related scenes, so scene truth sometimes requires checking serialized files directly.
- Runtime player architecture is still split across the stock `player.gd` path and the newer Lyra/Bachtavious branch.
- Weapon pickup live feel still needs an in-editor/manual walk-up verification pass with a screenshot or recording. The player headless path passes, AI capsule pickup passes, and `lyrasandbox.tscn` now places the new pickup scenes, but the stock `Sandbox.tscn` / `player.gd` main runtime path is still not migrated to this component.
- Weapon alignment live visuals still need an editor screenshot/manual review after tuning `pistol.tres` offsets against `Pistol_Aim_Neutral`.
- Vehicle prototype visual verification still needs a live/windowed screenshot because headless Godot uses the headless display server and cannot capture the viewport texture.
- Default headless CLI verification remains broken if `--log-file` is omitted; use the explicit log-file workaround instead.
- Documentation had drifted into multiple identities and orphan pages; this cleanup corrects the structure, but the underlying gameplay/runtime branch split remains.
- `Neo` now has initial canonical machine-readable state, structured per-loop proposal/result/decision artifacts, milestone evidence summaries, named gate profiles, registered visual evidence manifests, and generic Lyra AI-character visual proof. It still lacks richer per-profile thresholds, Lyra pickup/drop visual proof, weapon-alignment visual proof, and automatic promotion tooling.
- Lyra AI memory currently persists and restores summaries, but actor behavior does not yet use remembered state to change future utility choices, relationships, schedules, or dialogue.
- There is no shared health/death/recovery system yet for Lyra AI and players.

## Next Highest-Priority Action

- Implement the first shared life-system slice: add a reusable `LifeComponent`, wire it to Lyra AI actors and Bachtavious/player damage entrypoints, and prove `life_damaged` plus downed/death metrics in `lyrasandbox`.
- Make restored Lyra AI memory influence behavior after the life spine exists, preferably using life-event memory such as repeated damage, downed count, or last attacker.
- Extend the building milestone from one runtime barricade into multiple visible blueprint/build tasks, then connect build placement to waypoint/corridor routes. A later structural navigation step is still a real bake from sandbox collision geometry.
- Start the broader persistent-world vertical slice from the master plan after the Lyra memory behavior loop: log a theft event, persist a shopkeeper memory and relationship change, reload the game, and prove the shopkeeper behaves differently from saved memory.
- Upgrade `Neo` from workflow contract to stronger agent architecture by enriching gate profiles and adding promotion rules described in `docs/wiki/neo_architecture.md`.
- Keep `docs/ai/neo_state.json` current as the machine-readable source of truth for active goal, active scene, blockers, last verified evidence, recommended next loop, and evidence paths.
- Register real screenshot/video evidence for Lyra pickup/drop and weapon alignment through `tools/register_neo_visual_evidence.ps1`, then run `tools/neo_check.ps1 -GateProfileOverride lyra_visual`.
- Re-establish live verification on `Sandbox.tscn` and confirm that the active multiplayer spawn path lands on valid Terrain3D surface with the current `player.tscn` runtime.
- Live-test `level/scenes/lyrasandbox.tscn` in the editor and capture visual proof that walking near `PistolPickup.tscn` / `RiflePickup.tscn`, pressing `E`, and pressing `G` to drop behaves correctly.
- Open `level/scenes/weapons/WeaponCalibration.tscn` and tune `level/data/weapons/pistol.tres` offsets until the pistol aligns with Bachtavious hand poses.

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
- Optional Loop Mode support now exists through `docs/ai/neo_*`, `tools/neo_check.ps1`, and `tools/neo_loop.ps1`, but it is off by default.
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
- Global Performance HUD (**F9**) and `PerformanceStressTest.tscn` are operational for benchmarking.
- A new **Performance Engineering Skill** bundle and optimization wiki are established.
- NotebookLM-to-wiki research workflow is documented and supported by the existing wiki pages and `tools/` scripts.
- Headless Godot verification is usable again when runs pass an explicit repo-local `--log-file`; the default CLI log destination still crashes the mono executable on this machine.

## What Is Currently Broken Or Unconfirmed

- Live verification of Terrain3D collision and spawn placement in `Sandbox.tscn` is still pending.
- Godot MCP/editor state can be stale, especially around Lyra-related scenes, so scene truth sometimes requires checking serialized files directly.
- Runtime player architecture is still split across the stock `player.gd` path and the newer Lyra/Bachtavious branch.
- Weapon pickup live feel still needs an in-editor/manual walk-up verification pass with a screenshot or recording. The player headless path passes, AI capsule pickup passes, and `lyrasandbox.tscn` now places the new pickup scenes, but the stock `Sandbox.tscn` / `player.gd` main runtime path is still not migrated to this component.
- Weapon alignment live visuals still need an editor screenshot/manual review after tuning `pistol.tres` offsets against `Pistol_Aim_Neutral`.
- Default headless CLI verification remains broken if `--log-file` is omitted; use the explicit log-file workaround instead.
- Documentation had drifted into multiple identities and orphan pages; this cleanup corrects the structure, but the underlying gameplay/runtime branch split remains.

## Next Highest-Priority Action

- Continue refining Lyra AI navigation with a real navigation bake or explicit waypoint/corridor graph derived from sandbox collision geometry; the generated corridor nav now performs much better but still has occasional stuck events.
- Re-establish live verification on `Sandbox.tscn` and confirm that the active multiplayer spawn path lands on valid Terrain3D surface with the current `player.tscn` runtime.
- Live-test `level/scenes/lyrasandbox.tscn` in the editor and capture visual proof that walking near `PistolPickup.tscn` / `RiflePickup.tscn`, pressing `E`, and pressing `G` to drop behaves correctly.
- Open `level/scenes/weapons/WeaponCalibration.tscn` and tune `level/data/weapons/pistol.tres` offsets until the pistol aligns with Bachtavious hand poses.

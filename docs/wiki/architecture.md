# Architecture

Related:
- [[index|Wiki Index]]
- [[multiplayer|Multiplayer]]
- [[player_setup|Player Setup]]
- [[terrain3d|Terrain3D]]
- [[../ai/memory|AI Memory]]

## Purpose

This page records the actual high-level project structure: which directories are first-party game code, which scenes are active runtime paths, and which areas are still sandbox or addon space.

## Repository Zones

- `level/`: primary first-party gameplay code and scenes. This is the main project domain for multiplayer, player controllers, Terrain3D sandboxing, and AI experiments.
- `docs/ai/`: short operational memory for current project facts and handoff state.
- `docs/wiki/`: durable technical reference pages for subsystems and workflows.
- `addons/`: third-party and editor/plugin code, notably `terrain_3d`, `road-generator`, and `godot_mcp`.
- `assets/`: imported art, animation sources, props, fonts, and character assets used by the gameplay scenes.
- `demo/` and `road_demos/`: supporting example content and addon demonstration scenes, not the main gameplay runtime.
- `tools/`: offline helper scripts such as AI activity export tooling.

## Active Runtime Path

- `project.godot` currently runs `res://level/scenes/Sandbox.tscn`.
- `Sandbox.tscn` uses `level/scripts/level.gd` as the scene orchestrator.
- `level.gd` owns menu state, room selection, spawn orchestration, chat visibility, and some world bootstrapping such as the runtime flight pad.
- `Network` is an autoload backed by `level/scripts/network.gd`; it manages ENet session startup, peer registration, and the shared `players` registry.
- In the serialized `Sandbox.tscn`, both the exported `player_scene` and `MultiplayerSpawner` point to `res://level/scenes/player.tscn`.
- `player.tscn` plus `player.gd` therefore remain the active default multiplayer runtime, even though newer player-controller experiments exist elsewhere in the repo.

## Secondary Runtime Branches

- `Playground.tscn` with `character_body_3d.gd` is the local character-combat sandbox for Manny/Bachtavious shooting, recoil, ADS, and parkour iteration.
- `lyra_player_clean.tscn` with `bachtavious_multiplayer_player.gd` is a newer multiplayer-ready player candidate that merges the proven local shooter controller with the authority/chat hooks expected by `level.gd`.
- `lyrasandbox.tscn` is an alternate multiplayer sandbox branch, but the current serialized scene points to `lyra_player_clean_backup.tscn`, not `lyra_player_clean.tscn`.
- `BanditAI.tscn` is a separate AI sandbox with self-contained placeholder NPC behaviors and logging. It is architecturally separate from the multiplayer runtime.

## Architectural Shape

- The project follows a scene-centric architecture rather than a strict service/module architecture.
- `level.gd` acts as the composition root for the main runtime and currently carries multiple responsibilities: UI/menu flow, connection flow, spawn orchestration, chat gating, and some world setup.
- `player.gd` is a large behavior script that combines locomotion, combat, voice capture/playback, camera authority, respawn, and flight behavior in one controller.
- `network.gd` is intentionally small and mostly handles session events plus the replicated player registry.
- The newer Bachtavious controller path shows a cleaner direction: player-specific mechanics stay in the controller while preview-only content is removed at runtime and the scene graph is resolved explicitly.

## Current Strengths

- The project has a clear primary gameplay folder (`level/`) even though the repo also contains addons and demos.
- The current main scene, network autoload, and multiplayer player path are easy to identify from source.
- Sandbox scenes exist for character iteration, AI iteration, and alternate multiplayer/player experiments, which reduces pressure to change the main scene for every test.
- The repo-local memory and wiki system now provide a reasonable durable-context layer for future sessions.

## Current Risks

- The runtime is split across parallel player-controller branches: stock multiplayer in `Sandbox.tscn`, local shooter work in `Playground.tscn`, and Lyra/Bachtavious multiplayer in separate scenes.
- `level.gd` is accumulating responsibilities that would be easier to evolve if split into smaller scene services or child-controller nodes.
- Some docs had drifted from source, especially around which Lyra scene is actually wired into `lyrasandbox.tscn`.
- The repo includes addon demos and experimental scenes beside first-party game content, so broad scene scans can blur the architecture unless the runtime path is identified first.

## Consolidation Direction

- If Lyra/Bachtavious is the intended future runtime, promote that path deliberately by aligning `Sandbox.tscn`, `MultiplayerSpawner`, and the exported `player_scene` in one change.
- Keep `Playground.tscn` and `BanditAI.tscn` as explicit sandboxes, not ambiguous near-production branches.
- Consider splitting `level.gd` into scene-local controllers for menu/chat, spawning/session flow, and world bootstrapping once the main player path is settled.

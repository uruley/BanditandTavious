# Wiki Log

This is an append-only log of significant wiki and memory maintenance events.

## Entries

- 2026-04-25: Ran a 30-loop headless Lyra AI improvement pass, expanding generated navigation, adding runtime AI weapon pickups, adding actor inventory support, fixing per-loop metrics paths, and recording improved metrics: 30 valid 12-second loops averaged score `104.3337` with 15.8667 interactions, 3.9333 weapon pickups, and 1.3 stuck events; final 25-second comparison scored `185.52`.
- 2026-04-25: Added the weapon alignment workflow: `WeaponResource` now stores visual scale plus muzzle offsets, `WeaponMaster` auto-applies resource offsets in editor/runtime, `WeaponCalibration.tscn` previews weapons against Bachtavious pistol animations, and `lyra_player_clean.tscn` uses the proven Bachtavious hand-socket transform.
- 2026-04-25: Fixed Lyra weapon pickup test-level confusion by removing raw non-interactive rifle visuals from `lyrasandbox.tscn`, enlarging/raising the `WeaponPickup.tscn` collision sphere, and adding a nearby `weapon_pickups` fallback so `E` pickup works even without exact collision overlap.
- 2026-04-25: Added explicit interaction and drop semantics to the rebuilt Lyra weapon system: `PistolPickup.tscn` and `RiflePickup.tscn` require `E`, dropped weapons require `E` instead of auto re-pickup, and the Lyra bridge test now verifies explicit pickup plus `G` drop.
- 2026-04-25: Implemented the rebuilt Lyra/Bachtavious weapon pickup spine with `WeaponPickup.tscn`, `WeaponInventoryComponent`, `PistolPickup.tscn`, `RiflePickup.tscn`, and headless generic plus Lyra bridge tests; `lyrasandbox.tscn` now places the new pickup scenes instead of the legacy world-item scenes.
- 2026-04-25: Added a research-backed weapon-system decision: keep `WeaponResource`, visuals, and the `WeaponMaster` concept, but rebuild the pickup/equip spine after finding `lyrasandbox.tscn` scene-instance overrides that null out pickup defaults and after confirming the main `Sandbox.tscn` player branch still lacks the modular pickup API.
- 2026-04-24: Expanded the `lyrasandbox` AI prototype to 6 role-biased actors (`forager`, `hauler`, `scout`), wider generated sandbox nav, spread-out targets, and target cooldowns after stuck events; headless benchmark is `PARTIAL` with 4 successful interactions and 10 stuck events, showing broader travel now exercises blocked geometry that needs a real nav bake or waypoint graph.
- 2026-04-24: Moved the `lyrasandbox` AI prototype off the isolated test pad by default, placing its nav region and targets in the real sandbox play area; headless benchmark showed 12 successful interactions with 0 stuck events.
- 2026-04-24: Upgraded the `lyrasandbox` AI prototype with persistent target nodes, `NavigationAgent3D` movement, runtime nav region support, debug labels, and a headless benchmark showing 14 successful interactions with 0 stuck events.
- 2026-04-24: Implemented the first `lyrasandbox` AI vertical slice with runtime capsule gatherers, food/water/resource targets, task reservations, JSONL metrics, and a headless verification run showing successful interactions.
- 2026-04-24: Upgraded the shared `godot-ai` skill with a Lyra sandbox AI roadmap, loop-verification checklist, JSONL metrics schema, and parser for future Loop Mode/OpenRouter tuning.
- 2026-04-24: Added benchmark threshold presets and a bundled parser gate to the shared `godot-destructibles` skill so destruction logs can be checked with named `sphere`, `wall`, and `pillar` profiles.
- 2026-04-24: Added a reusable `DestructionBenchmark` scene/script for standardized projectile-vs-target destruction tests and updated the shared `godot-destructibles` skill to point to that benchmark path as the preferred headless validation workflow.
- 2026-04-24: Expanded the shared `godot-destructibles` skill with headless destruction verification guidance, explicit `--log-file` CLI workaround, and metrics-based validation patterns for shard count, spread, settle behavior, and frame timing.
- 2026-04-24: Added a repo-owned shared skills workflow with canonical `skills/`, a synced `godot-destructibles` skill bundle, and `tools/sync_shared_skills.ps1` for Gemini/Codex mirroring and installation.
- 2026-04-24: Expanded `[[destruction|Destruction]]` with localized wall-damage guidance, distinguishing whole-object replacers from chunked walls, CSG prototyping, and voxel/SDF approaches for bullet-vs-rocket impact scaling.
- 2026-04-24: Added optional `Neo` Loop Mode documentation and Windows-friendly PowerShell helpers (`docs/ai/neo_*`, `tools/neo_*`, `evals/*`) and documented that it is operator-triggered rather than always-on.
- 2026-04-24: Consolidated repo identity back to `Neo`, rewrote `GEMINI.md` as operator guidance instead of a competing persona, compressed `docs/ai/current-state.md`, and archived the older high-detail state to `docs/ai/archive/current-state-history.md`.
- 2026-04-24: Repaired wiki entrypoints by linking `fracturing_skill.md`, `parkour_design_document.md`, and the `fracturing-skill` subtree from `docs/wiki/index.md` and related pages.
- 2026-04-20: Created initial repo-local AI memory system in `docs/ai/` and replaced generated `AGENTS.md` with a curated routing file.
- 2026-04-20: Added domain wiki pages for Terrain3D and multiplayer.
- 2026-04-20: Added Obsidian-friendly index pages and wikilinks across `docs/ai/` and `docs/wiki/`.
- 2026-04-20: Established the four-layer knowledge model with `docs/ai/`, `docs/wiki/`, `docs/raw/`, and `AGENTS.md`.
- 2026-04-21: Integrated NotebookLM MCP and created "BanditandTavious Research" notebook.
- 2026-04-21: Added `[[destruction|Destruction]]` wiki page based on NotebookLM research into Godot 4 destructible objects.
- 2026-04-21: Added `[[player_setup|Player Setup]]` wiki page detailing Godot 4 3rd person character standards and coordinate systems.
- 2026-04-21: Added `[[portals|Portals]]` wiki page for 2-way teleportation and momentum preservation.
- 2026-04-21: Added `[[animations|Animations]]` wiki page detailing the Godot 4 Source-and-Library workflow for 3D assets.
- 2026-04-21: Added `[[parkour|Parkour]]` wiki page for dynamic vaulting, mantling, and geometric scanning.
- 2026-04-21: Adopted NotebookLM -> Obsidian wiki -> implementation as the preferred workflow for nontrivial system design and future reusable patterns.
- 2026-04-21: Added `[[ai_systems|AI Systems]]` wiki page based on NotebookLM research into Godot 4 NPC, enemy, companion, and villager architecture.
- 2026-04-21: Added `[[ai_training|AI Training Pipeline]]` page documenting `BanditAI` JSONL activity logs, SQLite export workflow, and first ML training target.
- 2026-04-22: Added `[[architecture|Architecture]]`, corrected multiplayer docs to match serialized scene wiring, and updated AI memory/current state after confirming that `Sandbox.tscn` still uses `player.tscn` while `lyrasandbox.tscn` points to `lyra_player_clean_backup.tscn`.
- 2026-04-22: Added `[[research_workflow|Research Workflow]]` and updated repo rules/memory so NotebookLM research is compiled into linked Obsidian knowledge instead of isolated report pages.
- 2026-04-23: Added `[[research_loop|Research Loop]]` plus automation scripts (`tools/run_research_cycle.ps1`, `tools/summarize_experiment.py`) to run multi-cycle headless experiments, generate gap analysis, and feed coach suggestions into the next cycle.

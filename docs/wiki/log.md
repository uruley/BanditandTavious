# Wiki Log

This is an append-only log of significant wiki and memory maintenance events.

## Entries

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

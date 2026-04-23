# Wiki Index

This section stores deeper reference material for important project domains.

## Domains

- [[terrain3d|Terrain3D]]
- [[multiplayer|Multiplayer]]
- [[architecture|Architecture]]
- [[research_workflow|Research Workflow]]
- [[destruction|Destruction]]
- [[player_setup|Player Setup]]
- [[portals|Portals]]
- [[animations|Animations]]
- [[ai_systems|AI Systems]]
- [[ai_training|AI Training Pipeline]]
- [[research_loop|Research Loop]]
- [[parkour|Parkour]]
- [[log|Wiki Log]]

## Page Catalog

- [[terrain3d|Terrain3D]]: Terrain3D setup, storage model, debugging workflow, and current project usage in `Sandbox.tscn`.
- [[multiplayer|Multiplayer]]: Spawn flow, authority, camera behavior, respawn logic, and multiplayer debugging guidance.
- [[architecture|Architecture]]: High-level repo structure, active runtime path, sandbox branches, and current consolidation risks.
- [[research_workflow|Research Workflow]]: How NotebookLM and external research should be compiled into linked project knowledge instead of isolated reports.
- [[destruction|Destruction]]: Technical patterns for mesh fracturing, physics (Jolt), and the replacer pattern for destructible objects.
- [[player_setup|Player Setup]]: Reference for 3rd person node hierarchy, coordinate systems (-Z forward), and camera pivot math.
- [[portals|Portals]]: Implementation standards for 2-way teleportation, loop prevention, and momentum preservation.
- [[animations|Animations]]: Standard workflow for decoupling models from animations, retargeting (BoneMap), and global libraries.
- [[ai_systems|AI Systems]]: Research-backed Godot 4 NPC architecture guidance for enemies, companions, villagers, navigation, perception, and phased implementation.
- [[ai_training|AI Training Pipeline]]: Runtime NPC activity logging plus JSONL to SQLite export and first trainable villager flee task.
- [[research_loop|Research Loop]]: Headless multi-cycle experiment orchestration, automated gap detection, and suggestion feedback loop.
- [[parkour|Parkour]]: Technical standards for dynamic vaulting, mantling, and geometric scanning patterns.
- [[log|Wiki Log]]: Append-only record of wiki maintenance and significant knowledge updates.

## Guidance

- Use `docs/ai/` for fast task-start context
- Use `docs/wiki/` for deeper subsystem details
- Add new wiki pages only when a subsystem has enough stable complexity to justify long-term documentation
- Read this file first during wiki retrieval so only the relevant deeper pages need to be opened

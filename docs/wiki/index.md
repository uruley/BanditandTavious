# Wiki Index

This section stores deeper reference material for important project domains.

## Domains

- [[terrain3d|Terrain3D]]
- [[multiplayer|Multiplayer]]
- [[architecture|Architecture]]
- [[neo_architecture|Neo Architecture]]
- [[research_workflow|Research Workflow]]
- [[destruction|Destruction]]
- [[player_setup|Player Setup]]
- [[portals|Portals]]
- [[animations|Animations]]
- [[ai_systems|AI Systems]]
- [[ai_training|AI Training Pipeline]]
- [[persistent_sandbox_ai|Persistent Sandbox AI Master Plan]]
- [[life_system|Life System]]
- [[research_loop|Research Loop]]
- [[interactions|Interaction System]]
- [[parkour|Parkour]]
- [[parkour_design_document|Parkour Design Document]]
- [[weapon_system|Modular Weapon System]]
- [[performance_engineering_skill|Performance Engineering Skill]]
- [[fracturing_skill|Fracturing Skill]]
- [[log|Wiki Log]]

## Supporting Pages

- [[performance-testing/SKILL|Performance Testing Skill Bundle]]
- [[fracturing-skill/SKILL|Fracturing Skill Bundle]]
- [[fracturing-skill/references/example_reference|Fracturing Skill Reference]]

## Page Catalog

- [[terrain3d|Terrain3D]]: Terrain3D setup, storage model, debugging workflow, and current project usage in `Sandbox.tscn`.
- [[performance_optimization|Performance Optimization]]: Professional Godot 4.x patterns for scaling AI, destruction, and rendering.
- [[multiplayer|Multiplayer]]: Spawn flow, authority, camera behavior, respawn logic, and multiplayer debugging guidance.
- [[architecture|Architecture]]: High-level repo structure, active runtime path, sandbox branches, and current consolidation risks.
- [[neo_architecture|Neo Architecture]]: Target design for Neo as a persistent evidence-driven agent with bounded loops, evaluation, and promotion of learning.
- [[research_workflow|Research Workflow]]: How NotebookLM and external research should be compiled into linked project knowledge instead of isolated reports.
- [[destruction|Destruction]]: Technical patterns for mesh fracturing, physics (Jolt), and the replacer pattern for destructible objects.
- [[player_setup|Player Setup]]: Reference for 3rd person node hierarchy, coordinate systems (-Z forward), and camera pivot math.
- [[portals|Portals]]: Implementation standards for 2-way teleportation, loop prevention, and momentum preservation.
- [[animations|Animations]]: Standard workflow for decoupling models from animations, retargeting (BoneMap), and global libraries.
- [[ai_systems|AI Systems]]: Research-backed Godot 4 NPC architecture guidance for enemies, companions, villagers, navigation, perception, and phased implementation.
- [[ai_training|AI Training Pipeline]]: Runtime NPC activity logging plus JSONL to SQLite export and first trainable villager flee task.
- [[persistent_sandbox_ai|Persistent Sandbox AI Master Plan]]: Persistence-first plan for durable NPC memory, SQLite world state, event logs, verification, and later training.
- [[life_system|Life System]]: Shared health, damage, downed, death, recovery, revive, respawn, metrics, and memory spine for players and Lyra/NPC actors.
- [[research_loop|Research Loop]]: Headless multi-cycle experiment orchestration, automated gap detection, and suggestion feedback loop.
- [[interactions|Interaction System]]: Professional Godot 4 architecture for weapon swapping, vehicle entry/exit, and NPC interaction components.
- [[parkour|Parkour]]: Technical standards for dynamic vaulting, mantling, and geometric scanning patterns.
- [[parkour_design_document|Parkour Design Document]]: Architectural blueprint for the node-based parkour FSM and traversal detection model.
- [[weapon_system|Modular Weapon System]]: Data-driven weapon resources, `WeaponMaster`, and the rebuilt pickup/equip spine for Lyra/Bachtavious weapons.
- [[fracturing_skill|Fracturing Skill]]: Step-by-step Blender-to-Godot destructible asset workflow linked to the destruction domain.
- [[bandit_test|Bandit Model Testing]]: Rigging and animation verification for the Bandit character.
- [[log|Wiki Log]]: Append-only record of wiki maintenance and significant knowledge updates.

## Supporting Catalog

- [[fracturing-skill/SKILL|Fracturing Skill Bundle]]: Skill-style operator guide for repeatable fracture authoring and Godot scene setup.
- [[fracturing-skill/references/example_reference|Fracturing Skill Reference]]: Supporting reference note kept linked so the subtree remains discoverable.

## Guidance

- Use `docs/ai/` for fast task-start context
- Use `docs/wiki/` for deeper subsystem details
- Add new wiki pages only when a subsystem has enough stable complexity to justify long-term documentation
- Read this file first during wiki retrieval so only the relevant deeper pages need to be opened

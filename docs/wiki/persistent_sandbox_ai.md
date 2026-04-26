# Persistent Sandbox AI Master Plan

Related:
- [[index|Wiki Index]]
- [[ai_systems|AI Systems]]
- [[ai_training|AI Training Pipeline]]
- [[research_loop|Research Loop]]
- [[neo_architecture|Neo Architecture]]
- [[life_system|Life System]]
- [[../ai/ai_masterplan|AI Masterplan]]

## Source

- Raw source: `docs/raw/masterplans/master_plan.pdf`
- Source title: `Persistent Sandbox AI Master Plan`
- Source version: `v1.0 - 2026-04-26`

## North Star

The target sandbox is not just reactive NPC behavior. The goal is a durable world where NPCs wake, work, eat, talk, fight, remember events, resume after restart, and give Neo/Hermes/Codex enough evidence to improve the system safely.

The plan explicitly recommends a persistence-first approach:

1. Make the world durable.
2. Log meaningful events.
3. Give NPCs persistent memories and relationships.
4. Use verification evidence before accepting AI changes.
5. Collect clean state-action-outcome logs before considering model training.

## Stack Direction

Start with Godot plus SQLite. PostgreSQL and pgvector are later options if multiplayer scale, remote access, or fuzzy semantic recall require them.

LLMs should not be used for per-frame movement. They fit better as slow-loop helpers for high-level planning, reflection, dialogue, research, experiment interpretation, and test/report synthesis.

## Core Runtime Layers

### Fast Godot Loop

Godot owns movement, physics, animation, combat, pathfinding, UI, and frame-critical decisions.

### Medium NPC Loop

NPC systems own schedules, utility scoring, task execution, memory lookup, relationships, inventory, and world-object interactions.

### Slow Agent Loop

Neo/Hermes/Codex should run bounded research and improvement cycles that inspect logs, propose small changes, verify outcomes, and record durable lessons.

### Offline Training Loop

Training is a future layer. The project needs stable logs, thousands of clean examples, consistent scoring, and known target behavior before model training becomes useful.

## Persistent World Model

The first durable database should track:

- world time
- NPC state
- world events
- NPC memories
- relationships
- schedules
- inventory
- world objects
- quest and rumor state
- experiment state

Suggested initial tables from the plan:

- `npcs`
- `world_time`
- `events`
- `npc_memories`
- `relationships`
- `schedules`
- `inventory`
- `world_objects`

## Event Logging Rules

Important gameplay actions should produce structured events. Useful event families include:

- player actions
- NPC actions
- life events such as damage, downed, death, recovery, revive, and respawn
- world-object changes
- witness records
- experiment records

Event-to-memory rules should convert meaningful events into NPC memory. High-importance events create memories, emotional events change relationships, repeated similar events create reflection opportunities, and exact world-truth events update durable state directly.

## First Vertical Slice

The best first persistent-sandbox milestone is:

1. Player steals from a shopkeeper.
2. A structured event is logged.
3. A shopkeeper memory is created.
4. The relationship changes.
5. The game closes.
6. The game reloads.
7. The shopkeeper remembers the theft.
8. The shopkeeper refuses sale, raises price, warns the player, or reacts differently.
9. Test output and screenshot evidence confirm the behavior.

This slice proves durable memory, relationship change, save/load, NPC behavior influence, and verification in one narrow loop.

## Verification Contract

Accepted AI improvements should have evidence:

- machine-readable logs or test results
- before/after scorecards
- screenshots for visible behavior
- explicit accept/reject decisions
- rollback safety for failed experiments

Reject changes that fail tests, do not improve scores, contradict visual evidence, weaken benchmarks, or reduce performance.

## Relationship To Current Lyra AI Work

The current Lyra sandbox work is a capability prototype: needs, utility goals, task execution, weapons, shooting, waypoint navigation, and visible building. The persistent sandbox plan adds the next strategic layer: those visible actions should eventually emit durable events and alter persistent world state.

The current small-milestone path remains useful, but the next architecture milestone should introduce persistence rather than only adding more behaviors.

### First Implemented Persistence Slice

The first Lyra persistence slice now exists as a JSON-backed memory log, not yet a full SQLite world model. `level/scripts/lyra_ai_memory_store.gd` writes actor memory summaries to `user://lyra_ai_memory.json` and appends event history to `user://lyra_ai_memory_events.jsonl`. `lyra_ai_metrics.gd` mirrors AI events into the memory store, and `lyra_ai_actor.gd` restores each actor's saved summary when `lyrasandbox` restarts.

Verified loop evidence in `logs/neo_loops/20260426_114246_loop_1/` shows the first reset run loaded 0 actor memories, while the second restarted run loaded 6 actor memories and emitted 6 `ai_memory_restored` events. This proves durable NPC memory survives restarting `lyrasandbox`.

This is intentionally narrower than the master plan. The next persistence step is to make restored memory affect behavior, then graduate durable world state to SQLite when the shopkeeper/theft or relationship slice begins.

## Guardrails

- Do not train a neural model first.
- Do not keep NPC truth only in prompts.
- Do not call LLMs per frame.
- Do not accept self-improvement changes without rollback and evidence.
- Do not weaken benchmarks to make changes pass.
- Do not treat runtime-spawned behavior as complete unless persistence and verification are explicit for persistence milestones.

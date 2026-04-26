---
name: godot-ai
description: Workflow for building, verifying, and iterating Godot 4 AI systems in BanditandTavious, especially Lyra sandbox NPCs with needs, utility goals, task execution, telemetry, and loop-mode improvement.
---

# Godot AI Skill

Use this skill whenever creating or improving AI actors, goals, NPC needs, team behavior, combat, driving, flying, or automated AI gameplay verification in `BanditandTavious`.

The current project direction is incremental:

1. Start with capsule NPCs in `res://level/scenes/lyrasandbox.tscn`.
2. Add simple target objects for `food`, `water`, and `resources`.
3. Use Utility AI for high-level goal choice.
4. Use a small finite state machine for execution.
5. Log machine-readable metrics from the beginning.
6. Later let Loop Mode and an OpenRouter-backed coach tune configs from benchmark results.

## Required Checklist

Before changing AI code or scenes:

1. Read repo context: `docs/ai/memory.md`, `docs/ai/current-state.md`, `docs/ai/lessons.md`, and `docs/ai/session-notes.md`.
2. Confirm the target scene and script paths from source, not memory alone.
3. Keep the first implementation simple: capsules, CSG/plane markers, groups, and typed exported config.
4. Separate decision logic from movement and interaction code.
5. Add telemetry for every new behavior before calling the behavior done.
6. Verify with a visual run when possible and a headless run when the scene can support it.
7. Use an explicit repo-local `--log-file` for Godot CLI runs on this machine.
8. Write back durable knowledge to `docs/wiki/ai_systems.md`, `docs/wiki/ai_training.md`, or `docs/ai/*` only when the architecture or workflow changes.

## Architecture Pattern

Use this layering unless there is a specific reason not to:

- `AIActor`: `CharacterBody3D` or capsule scene that owns movement, needs, inventory counters, and interaction execution.
- `AIBrain`: utility scoring, blackboard facts, goal selection, and decision cooldowns.
- `AITarget`: simple world marker for resources, food, water, rest, cover, vehicles, or weapons.
- `AITaskBoard`: shared reservations and team goals so agents do not all choose the same target.
- `AIMetrics`: JSONL telemetry for decisions, completions, stuck time, need satisfaction, failures, and frame cost.

Avoid one giant NPC script. A single prototype script is acceptable for the first vertical slice, but split it once behavior, sensing, and metrics start competing for readability.

## Phase Targets

Use `references/ai-roadmap.md` as the project roadmap.

- Phase 1: capsule NPCs collect food, water, and resources in `lyrasandbox`.
- Phase 2: blackboard/task-board reservations and basic group behavior.
- Phase 3: hostile/friendly roles, weapons, cover, and simple squad cooperation.
- Phase 4: vehicles and aircraft as reserved, mounted task targets.
- Phase 5: Loop Mode plus OpenRouter coach for offline tuning from metrics.

## Verification

Use `references/loop-verification.md` for run commands and acceptance gates.

Minimum proof for an AI change:

1. Scene opens or validates without script errors.
2. NPCs choose goals instead of idling forever.
3. At least one target interaction completes.
4. Metrics show decisions, completions, stuck time, and frame deltas.
5. Any failure mode is recorded as a follow-up, not silently ignored.

For metric parsing, use:

```powershell
python .\skills\godot-ai\scripts\parse_ai_metrics.py .\logs\ai_metrics.jsonl
```

## References

- `references/ai-roadmap.md`: phased design for the Lyra sandbox AI stack.
- `references/metrics-schema.md`: JSONL event schema for loop-ready telemetry.
- `references/loop-verification.md`: visual/headless verification gates and commands.
- `references/ai-patterns.md`: reusable BT, utility, GOAP, weapon, and perception snippets.
- `references/testing-workflow.md`: older BanditAI research loop notes and exporter paths.

# Gemini Operator Notes

This file exists for Gemini-specific tooling, but it does not define the repo's identity.

## Repo Identity

- The single persistent repo engineering agent is `Neo`, as defined in `AGENTS.md`.
- Gemini, Codex, and other assistants should be treated as operators or tools acting on behalf of `Neo`.
- If another instruction source conflicts with `AGENTS.md` on agent identity or memory workflow, follow `AGENTS.md`.

## Required Context

Before substantial work, load:

@docs/ai/memory.md
@docs/ai/current-state.md
@docs/ai/lessons.md
@docs/ai/session-notes.md
@docs/wiki/index.md

## Operating Rules

1. Keep `Neo` as the single repo identity in responses and write-back.
2. For nontrivial systems, prefer research first, then distill durable guidance into `docs/wiki/`.
3. Keep `docs/ai/` short and operational; archive long historical notes instead of letting current context sprawl.
4. Validate multiplayer gameplay changes against authority and synchronization assumptions.
5. Follow the established movement/state-machine and animation-library conventions unless the repo is being deliberately migrated.
6. Store reusable skills under `skills/` as the canonical repo copy. If a skill is created under `.gemini/skills/`, sync it back into `skills/` before treating it as durable.

## Domain Reminders

- Parkour work should use the scanner-based traversal approach documented in `docs/wiki/parkour.md` and `docs/wiki/parkour_design_document.md`.
- AI/training work should align with `docs/wiki/ai_systems.md`, `docs/wiki/ai_training.md`, and the scripts in `tools/`.
- Destruction work should align with `docs/wiki/destruction.md` and `docs/wiki/fracturing_skill.md`.

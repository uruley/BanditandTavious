# AGENTS.md

## Purpose

This repo uses a file-based memory system so agents can recover project context across fresh sessions.

## Knowledge Layers

This repo uses four knowledge layers:

1. `docs/ai/`
   Short operational memory for current project state and working rules.
2. `docs/wiki/`
   Curated durable knowledge written and maintained by the agent.
3. `docs/raw/`
   Immutable source materials such as copied tutorials, reference notes, external docs, and imported articles.
4. `AGENTS.md`
   The routing table and behavior contract for how the agent uses the other three layers.

Rules:

- `docs/raw/` is read-only for the agent unless the user explicitly asks to add or organize source materials.
- The agent may read from `docs/raw/` but should write synthesized knowledge into `docs/wiki/`, not back into raw files.
- `docs/ai/` should stay short and operational.
- `docs/wiki/` should store deeper, cleaned-up, durable knowledge.

## Required Read Order

Before doing substantial work, read these files in order:

1. `docs/ai/memory.md`
2. `docs/ai/current-state.md`
3. `docs/ai/lessons.md`
4. `docs/ai/session-notes.md`

Do not skip this step when the task touches gameplay, scenes, networking, Terrain3D, or project workflow.

## Targeted Autosearch Rule

If a memory file or wiki file points to a scene, script, domain doc, or repo path relevant to the current task, retrieve that file before making changes.

If the memory layer is insufficient to support a claim, search the codebase and confirm it from source before acting.

Prefer targeted retrieval over broad repo scans. Read the smallest set of files that can verify the fact or support the change.

## Domain Wiki Pointers

Read these deeper reference files when the task touches their domain:

- Terrain3D: `docs/wiki/terrain3d.md`
- Multiplayer: `docs/wiki/multiplayer.md`
- Wiki index: `docs/wiki/index.md`
- Wiki log: `docs/wiki/log.md`

Use the `docs/ai/*.md` files for fast operating context and the `docs/wiki/*.md` files for deeper project knowledge.

## Wiki Operations

### Research Distillation

When the user asks for NotebookLM research, external research, or a research-backed design pass:

1. Gather or query the source material.
2. Distill the result into durable project knowledge in `docs/wiki/`, not just a standalone report.
3. Update the existing domain page if one already covers the topic.
4. If a new page is needed, link it from `docs/wiki/index.md` and from at least one related wiki page.
5. Record the durable takeaway in `docs/ai/memory.md` or `docs/ai/current-state.md` when it changes workflow, architecture, or current direction.
6. Append a concise entry to `docs/wiki/log.md`.

Do not stop at “research notes” if the result should change how the project is understood or built. The target is a linked Obsidian knowledge base that compounds over time.

### Ingest

When the user asks to ingest a raw source:

1. Read the requested file in `docs/raw/`.
2. Extract durable project-relevant takeaways.
3. Write or update the corresponding page in `docs/wiki/`.
4. Add a short entry to `docs/wiki/log.md`.
5. Update `docs/wiki/index.md` if a new page was created or the summary changed materially.

Do not rewrite the raw source into `docs/ai/`. Put distilled knowledge in `docs/wiki/`.

### Query

When answering project questions:

1. Read `docs/ai/*` first.
2. Read `docs/wiki/index.md` to identify relevant deep pages.
3. Read only the wiki pages needed for the current task.
4. Verify against code or scene files if the claim is implementation-specific.

If a strong answer produces durable knowledge that is not yet captured, write it back into `docs/wiki/` or `docs/ai/` as appropriate.

### Lint

When asked to lint the wiki:

Check `docs/wiki/` for:

- contradictions between pages
- orphan pages with weak or no inbound references
- stale claims that conflict with current code or project state
- repeated concepts that deserve consolidation or a dedicated page
- weak summaries in `docs/wiki/index.md`
- missing significant events in `docs/wiki/log.md`

Then fix the documentation and append a lint entry to `docs/wiki/log.md`.

## Required Write-Back Rules

When durable project knowledge changes, update the relevant memory files before finishing:

- Update `docs/ai/memory.md` for stable facts, architecture, workflow, and file ownership.
- Update `docs/ai/current-state.md` for active blockers, recent fixes, and what is true right now.
- Update `docs/ai/lessons.md` after a user correction or after discovering a mistake pattern worth preventing.
- Update `docs/ai/session-notes.md` with a concise handoff when ending a thread with unfinished work or meaningful state.

When research changes project understanding, also make sure the result is woven into the wiki graph:

- update the most relevant domain page instead of creating isolated summaries when possible
- add or strengthen wikilinks between the new knowledge and existing project pages
- make the wiki readable as a second-brain knowledge base, not just a folder of reports

If nothing durable changed, leave the files untouched.

## Close-Out Checklist

When the user says `we are done for the day`, perform this checklist before ending the session:

1. Update `docs/ai/current-state.md` with the latest confirmed project state, blockers, and recent fixes.
2. Update `docs/ai/lessons.md` with any durable mistake-prevention rules learned during the session.
3. Update `docs/ai/session-notes.md` with a concise handoff summary, next steps, and open questions.
4. Update `docs/ai/memory.md` only if stable project facts or workflow rules changed.
5. Update the relevant `docs/wiki/*.md` files if deeper domain knowledge changed.
6. Append a concise handoff entry to `docs/wiki/log.md` if the session produced durable project knowledge or significant documentation changes.
7. In the final response, explicitly state which memory files were updated.

Do not skip this checklist when the user uses the exact phrase `we are done for the day`.

## Project Rules

- Verify the actual running scene before diagnosing scene-specific bugs.
- Treat Godot scene files and runtime state as separate sources of truth. Confirm both when debugging.
- Prefer repo facts over assumptions. If a memory file conflicts with code, inspect the code and then fix the memory file.
- Keep memory files concise and high-signal. Do not turn them into logs of every minor edit.
- When a task touches Terrain3D or multiplayer behavior, consult the corresponding wiki file before making durable claims.

## Current Focus Areas

- Godot 4.3 multiplayer gameplay
- player spawn, authority, and camera behavior
- Terrain3D setup in `level/scenes/Sandbox.tscn`
- repo-local AI memory workflow

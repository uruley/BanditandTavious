# Neo Architecture

Related:
- [[index|Wiki Index]]
- [[architecture|Architecture]]
- [[research_workflow|Research Workflow]]
- [[research_loop|Research Loop]]
- [[ai_systems|AI Systems]]
- [[../ai/memory|AI Memory]]

## Purpose

This page captures the target architecture for `Neo` as a persistent project agent that improves over time through evidence, bounded loops, and durable write-back.

## Current Shape

The repo already has the first layer of a real agent architecture:

- identity and contract in `AGENTS.md`
- short operational memory in `docs/ai/`
- deeper knowledge in `docs/wiki/`
- operator-triggered Loop Mode in `docs/ai/neo_loop.md`
- canonical machine-readable state in `docs/ai/neo_state.json`
- ranked next objectives in `docs/ai/neo_backlog.md`
- replayable loop artifacts under `logs/neo_loops/`
- manifest-backed visual evidence artifacts under `logs/visual_evidence/`
- repo-health plus named milestone-evidence gates in `tools/neo_check.ps1`
- headless research-cycle tooling in `tools/run_research_cycle.ps1` and `tools/summarize_experiment.py`
- repo-owned reusable skills under `skills/`

This is enough to make `Neo` a persistent engineering workflow, but not yet enough to make it a self-improving engineering agent in the stronger Hermes/OpenClaw sense. ^[inferred]

## What Is Missing

### 1. Canonical World State

`Neo` now has an initial machine-friendly state artifact at `docs/ai/neo_state.json` that says:

- current goal
- active branch/runtime path
- known blockers
- last verified evidence
- next recommended experiment
- trust level of each claim

The remaining work is to keep this file current after verification runs and teach milestone-specific tooling to consume its evidence paths and trust levels. ^[inferred]

### 2. Stronger Evaluation Layer

`tools/neo_check.ps1` currently checks repo health, main scene presence, file completeness, latest loop artifacts, Lyra AI metrics, batch summaries, Godot logs, registered visual artifact presence, and named milestone gate profiles. `docs/ai/neo_state.json` selects the active profile with `active_gate_profile`.

`Neo` should have layered evals:

- repo-health evals: files, scene presence, Git cleanliness
- runtime evals: Godot logs, errors, screenshots, scene-specific pass/fail
- behavior evals: metrics deltas, route visits, hit rate, stuck rate, build completion
- regression gates: explicit keep/revert thresholds per milestone

The current research loops and `neo_check.ps1` evidence gates provide part of this for Lyra AI. The `lyra_visual` profile now specifically requires a registered manifest-backed screenshot or recording, while the `lyra_ai_headless` profile stays focused on metrics and logs. The missing step is to enrich each profile with tighter thresholds so a building loop, combat loop, and visual-verification loop are judged differently. ^[inferred]

### 3. Proposal -> Run -> Judge -> Promote Pipeline

Loop Mode now has an initial artifact path under `logs/neo_loops/` for recording:

- `proposal.md`: what change is being attempted and why
- `before.json`: objective state before the change
- `result.json`: objective measurements and recommendation after the run
- `decision.md`: keep/revert/judge notes
- `lesson.md`: what should be promoted into memory/wiki/skills

The remaining work is to make the artifact pipeline consume milestone-specific evidence and automatically surface promotion candidates instead of only recording them. ^[inferred]

### 4. Promotion System For Learning

Right now, learning is partly manual:

- some lessons go to `docs/ai/lessons.md`
- some workflows become wiki pages
- some repeated patterns become skills

That is good, but the promotion rules should be explicit:

- if a pattern succeeds once: store it in session/current-state only
- if it succeeds repeatedly: promote to wiki guidance
- if it becomes reusable across operators/tools: promote to `skills/`
- if it changes how loops are judged: promote to `neo_check`, loop scoreboards, or benchmark scripts

This promotion ladder is what turns repeated work into a real second-order improvement system. ^[inferred]

### 5. Goal And Backlog Separation

The repo now separates the active goal, ranked backlog, scoreboard, and canonical state. The remaining risk is keeping those files synchronized as project evidence changes:

- `neo_goal.md`: one active objective only
- `neo_backlog.md`: ranked next milestones
- `neo_scoreboard.md`: keep/revert/eval thresholds
- `neo_state.json`: current machine-readable state

That keeps the agent from treating strategic backlog, tactical goal, and evaluation policy as the same thing. ^[inferred]

### 6. Cross-System Memory Compiler

The repo has two knowledge planes:

- repo-local memory/wiki
- external Obsidian vault

`Neo` should eventually compile both into one coherent graph:

- local operational memory for fast execution
- external Obsidian vault for long-term second-brain knowledge
- sync rules that decide what stays local, what gets exported, and what gets summarized

Without a compiler step, research and implementation can drift into parallel note systems. ^[inferred]

## Recommended Target Architecture

### Layer 1: Agent Kernel

Files:

- `AGENTS.md`
- `docs/ai/neo_goal.md`
- `docs/ai/neo_backlog.md`
- `docs/ai/neo_scoreboard.md`
- `docs/ai/neo_state.json`

Responsibility:

- define identity
- define active goal
- define bounded autonomy rules
- expose machine-readable current state

### Layer 2: Evidence Plane

Artifacts:

- headless metrics JSONL
- benchmark summaries
- Godot logs
- screenshots
- structured pass/fail reports

Visual evidence should be registered with `tools/register_neo_visual_evidence.ps1`, which copies the source capture into `logs/visual_evidence/YYYYMMDD_HHMMSS_<type>/` and writes `manifest.json` with the scene, evidence type, claim, source path, and registered evidence path. Raw unregistered media can help an operator inspect a problem, but the `lyra_visual` gate should not pass from loose files alone.

Responsibility:

- give `Neo` objective proof, not just intuition
- make every improvement loop evidence-backed

### Layer 3: Loop Engine

Components:

- `tools/neo_loop.ps1`
- `tools/neo_check.ps1`
- scenario-specific eval scripts
- research-cycle runners

Responsibility:

- run one bounded improvement cycle
- produce a structured judgment artifact
- decide whether the attempted change should be kept, reverted, or escalated for review

### Layer 4: Learning Compiler

Outputs:

- `docs/ai/lessons.md`
- `docs/wiki/*.md`
- `skills/*`
- external Obsidian vault sync

Responsibility:

- promote repeated successful patterns into durable reusable forms
- remove dependence on operator recollection

## Practical Next Steps

1. Keep `docs/ai/neo_state.json` current after verification runs and use it as the first machine-readable source of truth.
2. Keep `docs/ai/neo_backlog.md` ranked so `neo_goal.md` can stay single-goal.
3. Enrich each `tools/neo_check.ps1` milestone gate profile with active-goal thresholds, not just broad warnings.
4. Use `logs/neo_loops/YYYYMMDD_HHMMSS_loop_N/` as the replayable proposal/result/decision history for each bounded loop.
5. Standardize a promotion rule:
   - evidence -> lesson
   - repeated lesson -> wiki
   - repeated wiki workflow -> skill
   - repeated eval rule -> tooling

## Design Rule

If `Neo` cannot point to:

- the goal it is pursuing
- the evidence that the last change helped
- the rule it learned from that result

then it is still acting like a capable operator workflow, not yet like a self-improving engineering agent. ^[inferred]

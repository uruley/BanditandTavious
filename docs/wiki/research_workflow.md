# Research Workflow

Related:
- [[index|Wiki Index]]
- [[ai_systems|AI Systems]]
- [[architecture|Architecture]]
- [[../ai/memory|AI Memory]]

## Purpose

This page defines how research should enter the vault. The goal is a compounding Obsidian second brain, not a folder of disconnected reports.

## Standard

- Research starts from NotebookLM, external sources, or direct source ingestion.
- The output should update durable project knowledge in `docs/wiki/`.
- Prefer updating an existing domain page over creating a new isolated summary.
- If a new page is needed, link it from `index.md` and from at least one related wiki page.
- If the research changes project direction, workflow, or architecture, write the durable part back into `docs/ai/memory.md` or `docs/ai/current-state.md`.

## What Good Distillation Looks Like

- A domain page gains clearer guidance, constraints, patterns, or implementation order.
- Related pages reference each other with `[[wikilinks]]`.
- Open questions and unresolved decisions are preserved where they belong.
- The wiki log records that the knowledge base changed.

## What To Avoid

- One-off report pages with no inbound or outbound links.
- Research summaries that never update the existing subsystem pages they are supposed to inform.
- Keeping important direction changes only in chat history or memory files while the deeper wiki stays stale.

## Practical Rule

For this repo, every meaningful research pass should answer:

1. Which existing wiki page did this improve?
2. What new durable rule, pattern, or decision should future sessions inherit?
3. Where is this linked so it can be found again from the graph?

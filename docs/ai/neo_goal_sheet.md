# Neo Goal Sheet

Related:
- [[neo_goal|Neo Goal]]
- [[neo_backlog|Neo Backlog]]
- [[neo_scoreboard|Neo Scoreboard]]
- [[ai_masterplan|AI Masterplan]]
- [[current-state|Current State]]

## North Star

Build `BanditandTavious` into a persistent sandbox where Lyra/NPC agents can act, remember, reload memory after restart, and improve through bounded evidence-driven loops.

## Current Track

- Active scene: `res://level/scenes/lyrasandbox.tscn`
- Active agent identity: `Neo`
- Active gate profile: `lyra_ai_headless`
- Current milestone: establish a shared life-system spine so damage, downed/death, recovery, and memory events can work for Lyra AI and players.

## Completed Milestones

- Weapon pickup: complete.
- Basic AI shooting: complete.
- Waypoint-backed bigger navigation: complete for prototype.
- First visible build site: complete for one runtime barricade.
- Persistent memory log: complete for JSON actor summaries and event history.

## Next 3 Goals

1. Implement the first shared life-system slice.
   - Add a reusable `LifeComponent`.
   - Wire it to Lyra AI actors and Bachtavious/player damage entrypoints.
   - Prove `life_damaged` plus downed/death metrics in `lyrasandbox`.
2. Convert restored Lyra memory into behavior.
   - Use one remembered actor fact after restart.
   - Prefer a life-event fact such as repeated damage, downed count, or last attacker once the life spine exists.
   - Keep proof in `logs/neo_loops/`.
3. Start the persistent-world slice.
   - Log a theft event.
   - Persist shopkeeper memory and relationship change.
   - Reload and prove changed shopkeeper behavior.

## Do Not Drift Into

- Unbounded autonomous loops.
- Broad AI rewrites.
- Training models before clean state/action/outcome logs exist.
- LLM calls in frame-critical gameplay.
- Visual claims without screenshot or video evidence.

## Proof Required

- Headless behavior claims need JSONL metrics and `tools/neo_check.ps1`.
- Visual claims need registered evidence through `tools/register_neo_visual_evidence.ps1`.
- Persistence claims need at least two runs: one that writes state and one restarted run that loads state and behaves or logs differently.

## Current Keep/Revert Rule

- Keep small scoped changes that improve evidence, persistence, or one verified behavior.
- Revert or stop if errors increase, scene load fails, metrics stop parsing, or the loop makes the next decision less clear.

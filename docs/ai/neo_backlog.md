# Neo Backlog

Related:
- [[neo_goal|Neo Goal]]
- [[neo_scoreboard|Neo Scoreboard]]
- [[current-state|Current State]]
- [[../wiki/neo_architecture|Neo Architecture]]

## Purpose

This file holds ranked next objectives for `Neo` so `neo_goal.md` can stay focused on one active goal.

## Priority Order

1. Complete the first Neo kernel upgrade:
   - keep `docs/ai/neo_state.json` current
   - enrich each `neo_check.ps1` gate profile with more precise thresholds for its active goal
   - keep structured per-loop artifacts under `logs/neo_loops/` as the replayable loop history
2. Implement the first shared life-system slice:
   - add a reusable LifeComponent for health, damage, downed/death, recovery, and revive events
   - wire it to Lyra AI actors and Bachtavious/player damage entrypoints
   - prove `life_damaged` plus downed/death metrics in `lyrasandbox`
3. Convert restored Lyra AI memory into behavior:
   - use one remembered actor fact after restart
   - prove second-run behavior differs because memory was restored
   - keep the proof in a replayable `logs/neo_loops/` artifact
4. Start the persistent-world vertical slice from the master plan:
   - log a theft event
   - persist a shopkeeper memory and relationship change
   - reload and verify changed behavior from saved memory
5. Extend Lyra AI building from one runtime barricade into multiple visible blueprint/build tasks tied to waypoint/corridor routes.
6. Re-establish live verification on `Sandbox.tscn` and prove Terrain3D spawn placement works on the active multiplayer runtime.
7. Register live visual proof for Lyra pickup/drop and weapon alignment in `lyrasandbox.tscn` and `WeaponCalibration.tscn` through `tools/register_neo_visual_evidence.ps1`, then verify with the `lyra_visual` gate.

## Promotion Rule

- Move an item into `neo_goal.md` only when it becomes the single active objective.
- Remove or reorder backlog items only when project evidence changes the actual priority.

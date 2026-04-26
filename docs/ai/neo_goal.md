# Neo Goal

Related:
- [[neo_goal_sheet|Neo Goal Sheet]]
- [[neo_backlog|Neo Backlog]]
- [[neo_scoreboard|Neo Scoreboard]]

## Active Goal

- Goal: Progress the Lyra AI sandbox through small verified milestones: weapon pickup, shooting, bigger navigation, visible building, persistent memory, shared life system, then behavior that changes from saved memory.
- Status: Weapon pickup, basic shooting, waypoint-backed bigger navigation, the first visible building prototype, and the first persistent-memory log are satisfied as of 2026-04-26. The next preferred milestone is implementing the first shared health/damage/downed-death/recovery slice.

## Constraints

- Keep changes small and reviewable.
- Prefer project facts over assumptions.
- Do not switch Loop Mode on unless explicitly requested by the user.
- Stop early if the goal is satisfied or if verification is blocked by tooling/runtime limits.

## Goal Completion Signals

- `tools/neo_check.ps1` still reports the expected main scene and required memory files.
- Headless Lyra AI metrics show more successful interactions than the pre-pass baseline.
- Headless Lyra AI metrics include successful `weapon` interactions.
- Headless Lyra AI metrics include `shot_fired` events with successful hits for the shooting milestone.
- Headless Lyra AI metrics include `build_started`, `build_resource_delivered`, and `build_completed` events for the building milestone.
- Headless Lyra AI metrics include `ai_memory_loaded` and `ai_memory_restored` events for the persistent-memory milestone.
- Headless Lyra AI metrics include `life_damaged` and either `life_downed` or `life_died` events for the first life-system milestone.
- A restarted run shows at least one behavior difference caused by restored memory for the next memory-behavior milestone.
- Stuck events are reduced enough to justify keeping the scoped changes, with remaining stuck cases documented as follow-up navigation work.

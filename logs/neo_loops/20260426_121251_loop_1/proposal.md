# Neo Loop Proposal

- Created UTC: 2026-04-26T17:12:51Z
- Loop Index: 1
- Goal: Audit existing health/death/recovery code and propose the smallest shared life-system spine for Lyra AI and players
- Active Scene: res://level/scenes/lyrasandbox.tscn
- Recommended Next Loop: Implement shared health/damage/death logging for Lyra AI actors and prove it in lyrasandbox.

## Proposed Change

- Audit existing health, damage, death, recovery, and respawn code paths.
- Do not implement gameplay code in this loop.
- Produce the smallest shared life-system spine proposal for Lyra AI actors and players.
- Write durable findings into `docs/wiki/life_system.md`.

## Expected Evidence

- Search results identify existing life/damage fragments.
- `docs/wiki/life_system.md` documents the shared component proposal and first implementation acceptance criteria.
- `tools/neo_check.ps1` still passes after documentation/state write-back.

# Neo Loop Decision

- Decision: keep
- Recommendation: RECOMMEND KEEP
- Decided UTC: 2026-04-26T17:20:00Z

## Reasons

- The loop found there is no shared health/death/recovery spine yet.
- The audit identified concrete existing fragments and signature mismatches.
- `docs/wiki/life_system.md` now defines the smallest shared `LifeComponent` slice and acceptance criteria.
- No gameplay code was changed in this audit loop.

## Follow-Up

- Next loop should implement `LifeComponent` for Lyra AI actors and Bachtavious/player damage entrypoints, then prove `life_damaged` plus downed/death metrics in `lyrasandbox`.

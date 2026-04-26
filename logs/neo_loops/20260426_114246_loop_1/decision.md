# Neo Loop Decision

- Decision: keep
- Recommendation: RECOMMEND KEEP
- Decided UTC: 2026-04-26T16:45:40Z

## Reasons

- Run 1 wrote `user://lyra_ai_memory.json` and persistent event logs.
- Run 2 loaded six actor memories and emitted `ai_memory_restored` events for `Gatherer_01` through `Gatherer_06`.
- The change is scoped to AI memory logging and does not replace behavior selection yet.

## Follow-Up

- Next persistence loop should make one behavior use remembered state, for example bias a remembered successful goal or avoid a remembered stuck target.

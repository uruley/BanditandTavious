# Neo Loop Lesson

- Promotion Target: `docs/wiki/life_system.md`
- Status: promoted

## Lesson

- Before adding smarter combat or persistence behavior, establish a shared living-actor lifecycle. Damage, downed/death, recovery, revive, respawn, metrics, and memory events should come from one reusable `LifeComponent` for players and Lyra AI actors.

## Guardrail

- Do not migrate destructibles into the living-actor life system first. Living actors need downed/recovery/revive semantics; destructibles can keep their existing `destroy()` path until the actor lifecycle is stable.

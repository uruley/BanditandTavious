# Multiplayer Checklist

## Goal

Use this checklist when a Neo loop touches spawning, authority, synchronization, chat, or room flow.

## Checklist

- [ ] `Sandbox.tscn` runtime path is still the intended multiplayer path unless deliberately changed.
- [ ] `player_scene` and any spawnable scene configuration still agree.
- [ ] Authority-sensitive logic still checks the correct peer/ownership assumptions.
- [ ] Spawn placement is still coherent with the active level geometry.
- [ ] Chat/menu overlays still do not block the intended UI path.
- [ ] Any durable multiplayer lesson is written back to memory/wiki only after verification.

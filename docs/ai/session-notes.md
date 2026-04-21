# Session Notes

Related:
- [[memory|AI Memory]]
- [[current-state|Current State]]
- [[lessons|Lessons]]
- [[../wiki/index|Wiki Index]]

## Last Significant Session

- Investigated why the player was falling through the floor.
- Found the player collision shape in `player.tscn` had been disabled and re-enabled it.
- Determined earlier floor checks were misleading because the active debugging scene differed from the originally inspected scene.
- Identified that `Sandbox.tscn` relied on `Terrain3D` rather than a standard floor node.
- Set up repo-local Terrain3D data wiring for `Sandbox.tscn`.
- Added a repo-local AI memory system under `docs/ai` and updated `AGENTS.md` to enforce the read/write loop.

## Recommended Next Steps

- Re-establish Godot MCP connectivity and verify the live `Sandbox.tscn` terrain collision setup.
- Confirm the player lands on the Terrain3D surface in runtime.
- If spawn placement is still unreliable, adjust spawn logic to place players based on terrain height rather than a fixed `y = 100.0`.

## Open Questions

- Is the current Terrain3D data layout in `terrain_data` the final intended terrain for the sandbox, or only a bootstrap surface?
- Should `Mainland.tscn` also be migrated to Terrain3D, or remain separate from the sandbox experiment?

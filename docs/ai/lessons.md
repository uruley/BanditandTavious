# Lessons

Related:
- [[memory|AI Memory]]
- [[current-state|Current State]]
- [[session-notes|Session Notes]]

## Verified Patterns

- Do not assume the scene under investigation is the project main scene. Confirm `project.godot` and the actual scene open in the editor.
- A `CollisionShape3D` node can exist in the scene tree and still be nonfunctional if `disabled = true`.
- A Terrain3D node without a configured `data_directory` and region data should not be treated as a guaranteed walkable surface.
- For this project, generated AI context summaries from `codebase-md` are useful only as rough indexes, not as authoritative project memory.

## User Corrections To Preserve

- The goal is not just to patch immediate bugs but to build persistent memory and reusable workflow in the repo.
- When diagnosing “falling through the floor,” inspect the real active world setup, not only the player scene.

## Process Corrections

- For standalone character test scenes, copy the proven third-person camera rig pattern from `level/scenes/player.tscn` before treating the setup as ready.
- Do not change `project.godot` main scene as a convenience for testing without explicit user approval; prefer `F6` on the target scene or ask first.
- When menu buttons stop responding, inspect overlapping sibling `Control` nodes first. Hidden children under a still-visible parent `Control` can leave a mouse-blocking overlay over the menu.
- Avoid parallelizing dependent CLI steps like `init`, `scan`, and `generate` when later steps require files produced by earlier steps.
- On Windows, force UTF-8 output when running tooling that prints Unicode through Rich if console encoding issues appear.

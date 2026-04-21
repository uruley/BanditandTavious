# Terrain3D Wiki

Related:
- [[index|Wiki Index]]
- [[multiplayer|Multiplayer]]
- [[../ai/memory|AI Memory]]
- [[../ai/current-state|Current State]]

## Purpose

This file is the deep-storage reference for Terrain3D usage in this repo. Use it for setup, debugging, and workflow guidance that is too detailed for `docs/ai/memory.md`.

## Current Project Usage

- Primary Terrain3D experimentation scene: `res://level/scenes/Sandbox.tscn`
- Terrain node path in that scene: `Environment/Terrain3D`
- Current data directory used by the scene: `res://terrain_data`
- Current Terrain3D assets file used by the scene: `res://terrain_data/assets.tres`
- `TerrainDigger` in `Sandbox.tscn` is wired to the Terrain3D node for terrain interaction experiments.

## How Terrain3D Stores Data

- Terrain geometry is not defined only by the `.tscn` scene.
- Terrain3D expects a `data_directory` property pointing to a folder of terrain region files.
- Region files are typically named like `terrain3d_00_00.res`, `terrain3d_00-01.res`, or similar location-based names.
- The folder can also contain shared terrain assets such as `assets.tres`.

## Important Repo Paths

- Scene: `level/scenes/Sandbox.tscn`
- Terrain script helper: `level/scripts/terrain_dig.gd`
- Terrain data directory: `terrain_data/`
- Addon source and examples: `addons/terrain_3d/`
- Example configured Terrain3D scenes: `demo/Demo.tscn`, `demo/NavigationDemo.tscn`, `demo/components/DemoBenchmark.tscn`

## Recent Debugging History

- A temporary `CSGBox3D` floor was added during collision diagnosis to prove player physics worked independently of Terrain3D.
- That floor was later removed after wiring `Sandbox.tscn` to `res://terrain_data`.
- Earlier failures happened because the Terrain3D node in `Sandbox.tscn` had no configured `data_directory`, so it was not safe to assume the terrain had valid surface/collision data.
- Live editor verification of the current Terrain3D setup is still pending because Godot MCP connectivity has been unstable.

## Terrain3D Debug Checklist

When the player is not standing on terrain or terrain editing appears broken, verify:

1. The actual scene being run is the scene being inspected.
2. The `Terrain3D` node exists in the active scene.
3. `data_directory` points to a real repo folder.
4. That folder contains region `.res` files and expected assets.
5. The player spawn location is above a valid terrain area.
6. The player collider is enabled and sized correctly.
7. Live editor/runtime state matches the on-disk `.tscn` file.

## Terrain3D Editing Guidance

- Use Terrain3D as the actual walkable surface rather than leaving a fake diagnostic floor in place.
- Keep terrain data in repo-visible paths so it can be versioned and referenced by future sessions.
- If you bootstrap terrain from addon demo data, record that fact so future sessions know whether the terrain is temporary or intentional.
- When changing Terrain3D setup, update both `docs/ai/current-state.md` and this file if the workflow or storage layout changed.

## Open Questions

- Is `terrain_data/` meant to remain a bootstrap copy of demo terrain data or evolve into the project's real terrain source?
- Should spawn logic eventually sample terrain height instead of using a fixed Y value?

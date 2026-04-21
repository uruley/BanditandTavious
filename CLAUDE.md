# CLAUDE.md — BanditandTavious

## Required Reading

Before doing any substantial work, read these files in order:

1. `docs/ai/memory.md`
2. `docs/ai/current-state.md`
3. `docs/ai/lessons.md`
4. `docs/ai/session-notes.md`

Do not skip this step when the task touches gameplay, scenes, networking, Terrain3D, or project workflow. Full rules are in `AGENTS.md`.

## What Is This Project?

This project is an enhanced version of the original [Godot 3D Multiplayer Template](https://godotengine.org/asset-library/asset/3377) developed in Godot Engine 4.3. It builds upon the base template by adding several new features such as room-based multiplayer, proximity chat, and more.

## Quick Reference

- **Architecture**: monolith
- **Modules**: 8
- **Last scanned**: 2026-04-20 13:55:29.689131+00:00

## Architecture

**Type:** monolith

## Build & Run

_Build commands vary by project setup._

## Conventions

- **Naming:** mixed
- **File Organization:** flat
- **Import Style:** mixed
- **Patterns:** helper, model, pipe

## Modules

### addons
- **Path:** `addons`
- **Files:** 288

**Key Files:**
- `addons\godot_mcp\mcp_client.gd`
- `addons\godot_mcp\mcp_client.gd.uid`
- `addons\godot_mcp\mcp_ws_server.gd`
- `addons\godot_mcp\mcp_ws_server.gd.uid`
- `addons\godot_mcp\plugin.cfg`

### assets
- **Path:** `assets`
- **Files:** 113

**Key Files:**
- `assets\Environment\model.obj`
- `assets\Environment\model.obj.import`
- `assets\fonts\Kurland.ttf`
- `assets\fonts\Kurland.ttf.import`
- `assets\textures\Ground\coast_sand_rocks_02.bin`

### demo
- **Path:** `demo`
- **Files:** 60

**Key Files:**
- `demo\CodeGeneratedDemo.tscn`
- `demo\Demo.tscn`
- `demo\NavigationDemo.tscn`
- `demo\components\Borders.tscn`
- `demo\components\DemoBenchmark.tscn`

### level
- **Path:** `level`
- **Files:** 31

**Key Files:**
- `level\scenes\bullet.tscn`
- `level\scenes\csg_sphere_3d.gd`
- `level\scenes\csg_sphere_3d.gd.uid`
- `level\scenes\kitty_donut_shop.glb.import`
- `level\scenes\kitty_donut_shop_0.png.import`

### logs
- **Path:** `logs`
- **Files:** 1

**Key Files:**
- `logs\godot.log`

### road_demos
- **Path:** `road_demos`
- **Files:** 58

**Key Files:**
- `road_demos\demo_menu.gd`
- `road_demos\demo_menu.gd.uid`
- `road_demos\demo_menu.tscn`
- `road_demos\README.md`
- `road_demos\demo_resources\demo_ui.theme`

### terrain_data
- **Path:** `terrain_data`
- **Files:** 6

**Key Files:**
- `terrain_data\assets.tres`
- `terrain_data\terrain3d-01-01.res`
- `terrain_data\terrain3d-01_00.res`
- `terrain_data\terrain3d_00-01.res`
- `terrain_data\terrain3d_00-02.res`

### vulkan
- **Path:** `vulkan`
- **Files:** 1

**Key Files:**
- `vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5070.editor.cache`

## Git Insights

- **Branch:** `main`
- **Total commits:** 31
- **Contributors:** Ulysses Ruley

**Most Changed Files (Hotspots):**
- `level/scripts/player.gd`
- `level/scripts/level.gd`
- `project.godot`
- `level/scenes/Sandbox.tscn`
- `level/scenes/level.tscn`
- `level/scenes/player.tscn`
- `level/scripts/network.gd`
- `level/scenes/Mainland.tscn`
- `assets/characters/player/3DGodotRobot_GodotPalette.png.import`
- `assets/characters/player/GodotRobotPaletteSwap/GodotGreenPalette.png.import`

**Recently Modified:**
- `level/scripts/player.gd`
- `level/scripts/level.gd`
- `project.godot`
- `addons/terrain_3d/extras/particle_example/process_material.tres`
- `assets/Environment/Nature/Landscape/Ground068.png`
- `assets/Environment/Nature/Landscape/Ground068.png.import`
- `assets/Environment/Nature/Landscape/Ground068_1K-JPG.blend`
- `assets/Environment/Nature/Landscape/Ground068_1K-JPG.blend.import`
- `assets/Environment/Nature/Landscape/Ground068_1K-JPG.mtlx`
- `assets/Environment/Nature/Landscape/Ground068_1K-JPG.tres`

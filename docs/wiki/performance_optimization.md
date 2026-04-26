# Performance Optimization Guidance (Godot 4.x)

This document distills research and stress-test findings for high-performance systems in Godot 4, focusing on AI, destruction, and rendering.

## 1. Professional Monitoring & Profiling
- **In-Game HUD:** Use `Performance.get_monitor()` for standard metrics (FPS, Draw Calls, Physics Time).
- **Custom Monitors:** Use `Performance.add_custom_monitor("Category/Metric", callable)` to track project-specific counts like active AI or shards.
- **Logging:** For stress testing, use a thread-safe logger (leveraging a `Mutex` protected buffer) to write snapshots to a CSV for offline analysis.

## 2. Scaling AI (Horde Dynamics)
- **Node Overhead:** `CharacterBody3D` with `move_and_slide()` is the primary bottleneck. Performance often drops significantly beyond 100-200 active actors.
- **Server-Side AI:** When scaling to thousands of actors, bypass the SceneTree:
  - Create agents directly on the `NavigationServer3D` using RIDs.
  - Manage actor data in flat arrays (Data-Oriented Design) and apply transforms via the `RenderingServer` or `MultiMeshInstance3D`.
- **Update Batching:** Do not query navigation paths or physics every frame. Spread updates across multiple frames or use a low-frequency Timer for distant actors.

## 3. High-Density Destruction
- **Rendering Shards:** Thousands of shards can overwhelm the GPU with draw calls.
  - **MultiMeshInstance3D:** Collapses identical shard meshes into a single draw call.
  - **Chunking:** Divide the world into a grid of MultiMesh chunks to maintain effective culling.
- **Physics (Jolt):** 
  - **Overlapping Areas:** Heavy overlapping of `Area3D` nodes (even if non-monitoring) can cause Jolt performance to explode. Disable or move them once shards have settled.
  - **Kinematic Contacts:** Keep kinematic contact reporting disabled for shards unless strictly necessary.

## 4. Graphics & Rendering
- **SDFGI vs. VoxelGI:** Use SDFGI for large open environments, but be mindful of the performance cost on mid-range hardware. 
- **LOD (Level of Detail):** Use Godot 4's built-in Mesh LOD system aggressively for high-poly fractured assets.
- **Draw Call Reduction:** Combine static meshes where possible, or use the `RenderingServer` directly for procedural generation (e.g., roads).

## 5. Stress Test Baseline
Use the `res://level/scenes/PerformanceStressTest.tscn` to establish project-specific baselines:
- Record FPS at +100, +200, and +500 AI actors.
- Record Physics frame time spikes when shattering 50+ destructibles simultaneously.
- Toggle High/Low graphics presets to measure the impact of SDFGI and Shadows on the target hardware.

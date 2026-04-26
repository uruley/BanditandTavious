# Skill: Performance Engineering & Stress Testing

Expert guidance for benchmarking, profiling, and optimizing Godot 4.x applications, specifically targeting destruction, AI scaling, and high-end 3D graphics.

## Overview
This skill provides a standardized workflow for identifying performance bottlenecks, establishing hardware baselines, and implementing professional-grade optimizations using Godot's server-side APIs and performance singletons.

## Available Resources

### 1. Monitoring Tools
- **Global HUD (`PerfMon`):** Toggleable overlay (**F9**) tracking FPS, Physics Time, Draw Calls, and VRAM.
- **Custom Monitors:** Trackers for `AI/Active_Actors` and `Destruction/Active_Shards`.
- **CSV Logger:** Thread-safe metric recording to `user://performance_log.csv`.

### 2. Sandbox Environments
- **Stress Test Scene:** `res://level/scenes/PerformanceStressTest.tscn`
  - Grid-based spawning for batch AI (+100) and Destructibles (+50).
  - Runtime Graphics Presets (High/Low) for rendering impact analysis.

### 3. Documentation
- **Optimization Wiki:** `docs/wiki/performance_optimization.md`
  - Guidance on `RenderingServer`, `NavigationServer`, and `MultiMeshInstance3D`.

## Procedures

### 1. Establishing a Baseline
1. Open the **PerformanceStressTest** scene.
2. Toggle the HUD (**F9**) and note the "Idle" metrics (FPS, Draw Calls).
3. Switch to **High Graphics** and record the performance delta.
4. Use the **Start Logging** button to begin a recording session.

### 2. Stress Testing AI Scaling
1. In the sandbox, spawn AI in increments of 100.
2. Monitor **Physics Process Time**. 
3. **Threshold:** If Physics time exceeds 16ms (for 60fps targets) or 33ms (for 30fps), you have reached the `CharacterBody3D` limit.
4. **Action:** If the target count is higher than the limit, plan a migration to `NavigationServer3D` RIDs.

### 3. Stress Testing Destruction
1. Spawn 50 **Destructibles**.
2. Trigger an explosion and watch for the **Physics Spike**.
3. Monitor the **Active Shard Count**. 
4. **Optimization:** If shards are the bottleneck, ensure `cleanup_time` is tuned or implement `MultiMeshInstance3D` for visual shards.

### 4. Analyzing Logs
1. After a stress run, navigate to `user://performance_log.csv`.
2. Analyze the correlation between `ai_count` / `shard_count` and `fps` / `physics_ms`.
3. Use this data to define the "Performance Budget" for levels (e.g., "Max 150 AI per room").

## Professional Best Practices
- **Data-Oriented Design:** Prefer flat arrays of RIDs over thousands of SceneTree nodes for "horde" entities.
- **Server APIs:** Use `RenderingServer` and `PhysicsServer3D` directly for high-density objects.
- **Wait for Settlement:** Disable physics processing on shards once they have stopped moving (settled) to save CPU cycles.

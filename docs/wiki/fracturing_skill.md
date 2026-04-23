# Fracturing & Destruction Workflow

This guide explains how to use the automated Blender-to-Godot fracturing tool to create destructible objects.

## 1. Blender Preparation
1. Open your Blender scene.
2. Ensure you have the **Blender MCP** addon running on port **9876**.
3. Select the object you want to fracture (or note its name).

## 2. Using the Fracture Tool
Run the provided Python tool to automate the fracturing and export process:

```bash
# Usage: python tools/blender_fracture_tool.py <ObjectName> <ShardCount> <OutputPath>
python tools/blender_fracture_tool.py Cube 15 res://assets/fractured_cube.glb
```

**What this tool does:**
- Enables the `Cell Fracture` extension.
- Generates the specified number of shards.
- **Recenter Origins:** Automatically sets shard origins to the Center of Mass (Mass Volume), ensuring realistic physics rotation.
- **Renaming:** Adds the `-rigid` suffix to all shards, which Godot's importer uses to automatically create `RigidBody3D` nodes.
- **Material Indexing:** Sets interior face material index to 1.
- **Export:** Saves the result as a `.glb` directly into your Godot `assets/` folder.

## 3. Godot Implementation
1. **Assign Scene:** Create or use an existing object in Godot.
2. **Attach Script:** Attach `res://level/scripts/destructible.gd` to the object.
3. **Set Property:** In the Inspector, drag the exported `.glb` file into the `fractured_scene` property.
4. **Trigger Destruction:** Call the `destroy()` method on the object when it should break (e.g., in `take_damage()`).

## 4. Physics Configuration (Godot)
- Ensure your project is using **Jolt Physics** for stable shard behavior.
- The shards are imported as `RigidBody3D` with **Convex Collision** shapes (via the `-rigid` hint).
- You can adjust `shard_impulse` and `cleanup_time` on the `Destructible` script.

## 5. Performance Tips
- Keep shard counts low (**5–15**) for most objects.
- Use `cleanup_time` to remove shards after they've settled to save on physics calculations.
- Ensure shards are on a separate collision layer if they don't need to interact with players or other complex objects.

---
name: fracturing-skill
description: Comprehensive workflow for creating and implementing destructible objects in Godot using Blender. Use when the user wants to add objects that can break into physics-enabled shards upon damage or impact.
---

# Fracturing Skill

This skill provides a standardized multi-step workflow for creating "Fractured" or "Destructible" assets that transition from a single static/rigid object to multiple physics-driven shards in Godot.

## Workflow Overview

1.  **Blender Setup**: Generate shards and set up materials.
2.  **Physics Simulation**: (Optional) Bake physics to keyframes for cinematic breaks.
3.  **Export**: Export shards as a GLB with specific settings.
4.  **Godot Scene Setup**: Create a `RigidBody3D` using `res://level/scripts/destructible.gd`.
5.  **Shard Wiring**: Assign the GLB as the `fractured_scene` in the inspector.

---

## Detailed Procedures

### 1. Blender: Shard Generation
- **Addon**: Enable "Cell Fracture" (standard Blender addon).
- **Setup**: Select the object.
- **Fracture**: 
    - `Source Limit`: Number of shards (10-20 for small, 50+ for large).
    - `Noise`: 0.1 - 0.2 for jagged breaks.
    - `Material Index`: Set to 1 (uses second material slot for inner faces).
- **Cleanup**: Select all shards -> `Object` -> `Rigid Body` -> `Add Active`. Set `Collision Shape` to `Convex Hull`.

### 2. Blender: Materials
- **Exterior (Slot 0)**: The material seen before it breaks.
- **Interior (Slot 1)**: The material seen inside the cracks. 
    - **Tip**: Set high **Emission Strength** (e.g., 20.0) for a glowing "Lava" effect.

### 3. Godot: Scene Construction
Every destructible object must follow this node structure:
- `RigidBody3D` (root) -> Script: `res://level/scripts/destructible.gd`
    - `MeshInstance3D`: The "Solid" version of the object.
    - `CollisionShape3D`: Collision for the solid version.

**Required Script Settings (Inspector):**
- `Fractured Scene`: Path to the exported `.glb` or `.tscn` containing the shards.
- `Health`: How many shots it takes to break.
- `Collision Layer`: 1 (Player/Destructible).
- `Collision Mask`: 3 (World + Bullets).
- `Contact Monitor`: ON.
- `Max Contacts Reported`: 10.

### 4. Code Compatibility
The `destructible.gd` script expects a `take_damage(amount, _from_id)` and `destroy(direction)` method.
The bullet/projectile must call these on impact:
```gdscript
if body.has_method("take_damage"):
    body.take_damage(damage)
```

## Best Practices
- **Triplanar Mapping**: Use Triplanar materials in Godot for the interior faces to avoid UV stretching on jagged shards.
- **Collision Optimization**: Shards should use `Convex Hull` collision shapes.
- **Cleanup**: `destructible.gd` includes a `cleanup_time` variable to automatically remove shards after they settle.

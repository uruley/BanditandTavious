---
name: godot-destructibles
description: Workflow for creating and configuring destructible 3D assets in Godot using Blender fracturing tools. Use when building objects that need to shatter into physical shards (e.g., pillars, crates, walls) upon impact or damage.
---

# Godot Destructibles Workflow

This skill automates the creation of "Replacer Pattern" destructibles: static objects that swap for a collection of physical shards on impact.

## 1. Blender Fracturing Workflow

Use the project-local `tools/blender_fracture_tool.py` to generate the fractured asset. This tool handles the critical `-rigid` naming convention required for Godot 4's physics importer.

### Fracture Command
Execute this from the project root:
```bash
python tools/blender_fracture_tool.py <BlenderObjectName> <ShardCount> <OutputPath>
```
*   **BlenderObjectName**: The name of the mesh inside your open Blender instance.
*   **ShardCount**: Number of pieces (e.g., 10 for small crates, 50 for large pillars).
*   **OutputPath**: The `res://` path for the resulting GLB (e.g., `res://assets/fractured_pillar.glb`).

### Critical Suffix Rule
Godot only converts meshes to `RigidBody3D` automatically if they end with `-rigid`. The fracture tool handles this, but if doing manual edits:
*   Object Name: `Shard_01-rigid`
*   Mesh Data Name: `Shard_01-rigid` (Godot often checks data names first).

## 2. Godot Scene Setup

A destructible object consists of two parts: the **Static Wrapper** and the **Fractured Shards**.

### Creating the Destructible Scene (.tscn)
1.  **Root Node**: Create a `RigidBody3D` (e.g., `DestructibleBox`).
2.  **Script**: Attach `res://level/scripts/destructible.gd`.
3.  **Visuals**: Add a `MeshInstance3D` child. **CRITICAL**: You must assign a `Mesh` resource (e.g., `BoxMesh`) and set its size to match the collision.
4.  **Collision**: Add a `CollisionShape3D` matching the mesh dimensions.
5.  **Assign Shards**: Set the `fractured_scene` export variable to the GLB generated in step 1.

### MANDATORY VERIFICATION
Before reporting success, use `read_file` on the new `.tscn` and verify:
*   [ ] The root node is named correctly (not just "Node").
*   [ ] The `MeshInstance3D` node has a `mesh` property with a valid sub-resource.
*   [ ] `fractured_scene` points to a valid `.glb` path.

### Script Configuration
Adjust these exports on the root node for stability:
*   **Impact Threshold**: `2.0` (Standard for floor-spawned objects to prevent self-shattering).
*   **Invulnerability Time**: `0.5` (Prevents breaking on spawn frame).
*   **Health**: Set as needed for projectile damage.
*   **Mass Resistance**: Prevents tiny objects from shattering huge ones.

## 3. Interaction Mechanics

### Dealing Damage
Projectile or melee scripts should call `take_damage(amount)` on the destructible.
```gdscript
if body.has_method("take_damage"):
    body.take_damage(1.0)
```

### Forcing Destruction
To shatter an object without health depletion (e.g., a scripted event):
```gdscript
body.destroy(impulse_direction)
```

## 4. Troubleshooting

*   **Shards float in air**: The GLB was imported as `MeshInstance3D`. Re-run the fracture tool to ensure the `-rigid` suffix is applied.
*   **Breaks on spawn**: Increase `invulnerability_time` or `impact_threshold`.
*   **Shards are wrong size**: Ensure the unbroken object has its scale applied/inherited correctly. The script forces `shards.scale = scale`.

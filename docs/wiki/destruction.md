# Destructible Objects & Chaos-Style Destruction

This page outlines the technical implementation patterns for creating destructible environments in Godot 4, mimicking systems like Unreal Engine's Chaos.

## Core Physics Foundation: Jolt

For high-performance destruction involving numerous shards, the default Godot physics engine is often insufficient.

- **Recommendation:** Use **Jolt Physics**.
- **Benefits:** Higher stability, better performance with hundreds of colliding shards, and reduced "jittering."
- **Setup:** `Project Settings > Physics > 3D > Physics Engine` set to `Jolt Physics`.
- **Optimization:** Enable `simulation/allow_sleep` (formerly `sleep/enabled`) so shards stop consuming CPU once they settle.

## The Replacer Pattern

The industry-standard workflow for Godot 3D destruction is replacing an intact object with a fragmented version at runtime.

### 1. The Intact Object
- Typically a `StaticBody3D` or `Area3D`.
- Responsible for health management and impact detection.

### 2. The Fragmented Scene
- A separate `.tscn` file.
- Contains multiple `RigidBody3D` nodes (shards).
- Each shard should have its own `MeshInstance3D` and `CollisionShape3D`.

### 3. The Transition Logic
When the object "dies":
1. Instance the **Fragmented Scene** at the `global_transform` of the intact object.
2. Apply a `central_impulse` to each shard based on the direction of the killing blow.
3. Call `queue_free()` on the intact object.
4. (Optional) Implement a timer to fade out or remove shards after X seconds to maintain performance.

## Content Creation Workflow (Blender to Godot)

Efficient destruction starts in the modeling software.

- **Fracturing:** Use the **Cell Fracture** addon in Blender.
- **Shard Limit:** Aim for **5–20 shards** for standard props; higher counts for hero assets only.
- **Origin Points:** Crucial—Set `Origin to Center of Mass (Volume)` for all shards before export so they rotate correctly when physics take over.
- **Import Hints:** Use suffixes in Blender like `-rigid` or `-convcol`. Godot will use **VHACD (Convex Decomposition)** during import to generate precise collision shapes automatically.

## Useful Plugins & Tools

- **Godot Destruction Plugin (Jummit):** Automates the replacement logic.
- **MeshDataTool:** For advanced developers wanting to modify meshes/terrain in real-time (more complex than the replacer pattern).

## Performance Checklist
- [ ] Physics engine set to Jolt.
- [ ] Shards use Convex Collision shapes (avoid Trimesh/Concave for performance).
- [ ] Shards have a cleanup/despawn timer.
- [ ] Shards belong to a specific collision layer to avoid unnecessary checks with complex gameplay nodes.

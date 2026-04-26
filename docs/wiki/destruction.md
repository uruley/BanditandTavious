# Destructible Objects & Chaos-Style Destruction

Related:
- [[index|Wiki Index]]
- [[fracturing_skill|Fracturing Skill]]
- [[architecture|Architecture]]
 
This page outlines the technical implementation patterns for creating destructible environments in Godot 4, mimicking systems like Unreal Engine's Chaos.

## Current Repo Baseline

The current project already has whole-object destruction paths:

- `level/scripts/destructible.gd`: health-driven replacer pattern that swaps an intact object for a pre-fractured `fractured_scene` and impulses all shards.
- `level/scripts/animated_destructible.gd`: health-driven destruction via a pre-authored fracture animation.

These are good for crates, props, and one-shot breakables. They are not enough for selective wall damage, because they always treat the object as a single destruction unit.

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

## Localized Wall Damage

If the design goal is:

- bullets remove only a small chipped area
- rockets open a larger hole
- unsupported sections can break off later

then the wall cannot stay a single destruction unit. It needs internal structure.

### Recommended Pattern For This Project: Chunked / Cell-Based Walls

Use a wall made of many small cells or chunks instead of one monolithic mesh.

Recommended structure:

- intact wall = grid of cells or chunk scenes
- each cell starts as static / anchored
- hit processing converts only the impacted cells into destroyed, hidden, or fractured state
- disconnected groups can later detach and become `RigidBody3D` chunk fragments

Weapon mapping:

- bullet: damage radius of 1 to 2 cells, mostly visual chip plus maybe one removed cell
- shotgun: short cone or small cluster of neighboring cells
- rocket: larger spherical radius across several cells, then run a support check so loose sections can fall

Why this fits Godot well:

- it keeps collision simple and deterministic
- it matches the repo's existing replacer workflow
- it lets destruction scale by weapon radius instead of requiring runtime mesh surgery
- it is multiplayer-friendlier than arbitrary per-triangle mesh edits

Two practical variants:

1. **GridMap wall**
   - Best when the wall already fits a regular brick/block grid.
   - Godot's `GridMap` is scriptable and internally partitioned into octants for rendering and physics.
   - On hit, convert the impact point to cell coordinates and clear or replace only those cells.

2. **Custom chunk scene**
   - Best when the wall needs custom art but should still break in authored pieces.
   - Build the wall from chunk nodes (for example 0.5m, 1m, or brick-sized pieces).
   - Each chunk can hold health, support state, and an optional fractured replacement.

### Support / Collapse Logic

Localized destruction only feels correct if unsupported material can detach.

Recommended rule:

- keep chunks static while they remain connected to an anchor set (floor, side columns, steel frame, etc.)
- after a blast, run a flood-fill or graph traversal from anchors
- any remaining chunk group not connected to an anchor is converted into a falling rigidbody cluster or despawned into shard FX

This gives the behavior you asked for:

- bullet hit: only a small area breaks
- rocket hit: a bigger hole appears
- if enough support is removed, half the wall can finally fall

## Alternatives And When To Use Them

### CSG Subtraction

Godot CSG supports subtraction, so it can carve dents or holes from a wall-like volume.

Use it for:

- prototypes
- rare hero-object breaches
- editor-authored experiments you plan to bake later

Do not choose it as the default runtime wall-destruction system. Godot's docs explicitly position CSG as a prototyping tool with significant CPU cost, and recommend baking results into static geometry for final use.

### Voxel / SDF Destruction

If you need truly arbitrary holes anywhere on the same object, voxel/SDF walls are the strongest option.

Typical flow with Voxel Tools:

- represent the wall as editable voxels or smooth SDF volume
- bullets subtract a tiny sphere
- rockets subtract a larger sphere
- meshing rebuilds only the edited local volume

Strengths:

- most flexible shape control
- natural "dig a hole anywhere" behavior
- easy weapon scaling by radius and falloff

Costs:

- higher implementation complexity
- different asset pipeline than the current mesh/chunk setup
- support/collapse behavior still needs a second system if you want large pieces to fall as rigidbodies

Important constraints from the docs:

- only the nearest LOD is editable in `VoxelLodTerrain`
- `VoxelModifier` subtraction works only with `VoxelLodTerrain` smooth terrain

## Recommended Decision

For this project, the best path is not "cut arbitrary holes in one wall mesh at runtime" as the default system.

The best path is:

1. Keep the current whole-object replacer system for props.
2. Build gameplay walls as chunked destructible assemblies.
3. Apply per-weapon radius to chunks so bullets chip, rockets breach, and unsupported groups collapse.
4. Reserve CSG for prototyping and voxel/SDF only if the design truly requires freeform holes anywhere on a single surface.

This is the best tradeoff between:

- believable selective destruction
- stable collision
- Godot implementation cost
- future multiplayer replication

## Implementation Sketch

Minimal wall data model:

- `DestructibleWall`
- array/dictionary of chunk records
- anchor flags for structural support
- weapon profiles with `damage_radius`, `impulse`, and `collapse_threshold`

Hit flow:

1. Projectile reports impact point and weapon profile.
2. Wall converts impact point into local cell/chunk coordinates.
3. Wall finds chunks inside the radius.
4. Impacted chunks are hidden, removed, or swapped to fractured mini-scenes.
5. Wall runs support traversal from anchor chunks.
6. Unanchored chunk groups detach into rigid bodies or shard FX.

This should be the next implementation layer above the current `destructible.gd`, not a replacement for every destructible object in the game.

## Content Creation Workflow (Blender to Godot)

Efficient destruction starts in the modeling software.

- **Fracturing:** Use the **Cell Fracture** addon in Blender.
- **Shard Limit:** Aim for **5–20 shards** for standard props; higher counts for hero assets only.
- **Origin Points:** Crucial—Set `Origin to Center of Mass (Volume)` for all shards before export so they rotate correctly when physics take over.
- **Import Hints:** Use suffixes in Blender like `-rigid` or `-convcol`. Godot will use **VHACD (Convex Decomposition)** during import to generate precise collision shapes automatically.

## Useful Plugins & Tools

- **Godot Destruction Plugin (Jummit):** Automates the replacement logic.
- **MeshDataTool:** For advanced developers wanting to modify meshes/terrain in real-time (more complex than the replacer pattern).
- [[fracturing_skill|Fracturing Skill]]: repo-local Blender-to-Godot fracture workflow and linked skill bundle.

## Performance Checklist
- [ ] Physics engine set to Jolt.
- [ ] Shards use Convex Collision shapes (avoid Trimesh/Concave for performance).
- [ ] Shards have a cleanup/despawn timer.
- [ ] Shards belong to a specific collision layer to avoid unnecessary checks with complex gameplay nodes.

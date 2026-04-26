# Godot Destructibles Checklist

Run this checklist before handing off any destruction work.

## Blender / Source Asset

- [ ] Correct object was fractured or authored for the requested destruction mode.
- [ ] Shard count matches the asset scale and gameplay need.
- [ ] Shard origins were recentered for stable rigidbody behavior.
- [ ] Exterior material is intentional.
- [ ] Interior fracture material is intentional.
- [ ] Export path is correct for the Godot project.

## Godot Import

- [ ] Exported `.glb` or scene exists at the expected path.
- [ ] Import did not silently strip the intended structure.
- [ ] Shards are recognized in the imported asset the way the pipeline expects.

## Godot Intact Scene

- [ ] Intact root node type is correct.
- [ ] Intact `MeshInstance3D` exists.
- [ ] Intact mesh resource is assigned.
- [ ] Intact material is assigned or intentionally inherited.
- [ ] `CollisionShape3D` exists.
- [ ] Collision shape is the correct approximate size.
- [ ] Collision is enabled.
- [ ] Destruction script is attached.
- [ ] `fractured_scene` or equivalent reference is assigned.

## Script / Gameplay Wiring

- [ ] Damage path reaches `take_damage()` or equivalent.
- [ ] Forced destruction path reaches `destroy()` or equivalent.
- [ ] Cleanup / shard lifetime settings are intentional.
- [ ] Collision layers and masks are intentional.

## Runtime Verification

- [ ] Scene launches without new script/parser errors.
- [ ] Object is visible in runtime.
- [ ] Object has collision in runtime.
- [ ] Hit test produces the expected destruction behavior.
- [ ] Shards or animation appear at the correct position/scale.

## Handoff Rule

Do not say the destructible is complete if any of the following are still unknown:

- whether the intact mesh is visible
- whether the material is assigned correctly
- whether collision is enabled
- whether the fractured reference is set
- whether a runtime hit actually works

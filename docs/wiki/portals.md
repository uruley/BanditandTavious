# 3D Portal & Teleportation System

Technical standards for implementing seamless, 2-way teleportation in Godot 4.

## Core Logic: Seamless Transformation

To ensure a player exits a portal with the same relative position, rotation, and momentum they had when entering, you must use transformation matrices.

### The Transformation Formula
```gdscript
# Transform player from World Space -> Entrance Local Space -> Exit World Space
player.global_transform = exit_portal.global_transform * (entrance_portal.global_transform.affine_inverse() * player.global_transform)
```

### Preserving Momentum
For `CharacterBody3D`, the velocity must also be rotated to match the exit portal's orientation:
```gdscript
var local_velocity = entrance_portal.global_transform.basis.affine_inverse() * player.velocity
player.velocity = exit_portal.global_transform.basis * local_velocity
```

## Loop Prevention (Infinite Back-and-Forth)

Preventing immediate re-teleportation upon arrival at the destination portal.

1.  **Velocity Check (Recommended):** Only trigger teleportation if the player is moving **toward** the portal face. Upon exit, they will be moving **away** from the destination face, naturally preventing a loop.
2.  **Exit Offset:** Place the player at a `Marker3D` positioned slightly in front of the exit portal's collision volume.
3.  **Cooldown:** Use a short timer (e.g., 0.1s) or a "last_portal" reference to ignore the destination portal temporarily.

## Multiplayer Synchronization

1.  **Authority:** The node with `Multiplayer Authority` (usually the player client) should detect the collision and perform the transform update.
2.  **Physics Interpolation:** **CRITICAL.** Godot 4's physics interpolation will cause massive "rubber-banding" or visual streaks if not reset.
    - Call `player.reset_physics_interpolation()` immediately after setting the new `global_transform`.
3.  **Reliable RPC:** Trigger the teleport via a `Reliable RPC` to ensure all clients snap the player's position in the same frame.

## Recommended Scene Structure
- **Portal** (Area3D)
    - **MeshInstance3D** (Visual representation)
    - **CollisionShape3D** (The trigger volume)
    - **Marker3D** (The "Spawn Point" for arrivals)
    - **Script** (Handles linking and transformation math)

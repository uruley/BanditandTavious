# Parkour & Environmental Interaction

Technical standards for implementing dynamic vaulting, mantling, and step-up logic in Godot 4.

## Geometric Scanning Pattern
Instead of pre-defining every climbable ledge, the player uses a "Scanner" system to probe the geometry in front of them.

### Scanner Node Setup
Add these `RayCast3D` nodes as children of the `CharacterBody3D` (or a dedicated `Scanner` child):

1.  **ForwardRay (Waist Height):** Detects if an obstacle is in front.
2.  **HeadRay (Head Height):** Used to distinguish between a Hurdle and a Mantle.
3.  **LedgeRay (Downward):** Positioned dynamically to find the top surface height.

### Logic Flow
- **Step Up (Stairs):** If a very low obstacle (0.2m - 0.4m) is detected, the player's Y position is nudged up instantly.
- **Vault/Hurdle (Waist High):** If `ForwardRay` hits but `HeadRay` is clear, the obstacle is waist-high.
    - Action: Trigger vault animation and tween the player across the obstacle.
- **Mantle (Head High):** If `HeadRay` hits, but there is clear space above it (Head Clearance check).
    - Action: Trigger ledge-grab animation and pull the player up to the top.

## Procedural Positioning (The "Finish" Point)
To ensure the player lands perfectly on the ledge:
1.  **Detect Hit:** Use `LedgeRay` to find the `collision_point` on top of the obstacle.
2.  **Target Point:** This hit point + half the player's capsule height is the `target_position`.
3.  **Tween:** Use `create_tween()` to move the `global_position` from current to target over 0.2 - 0.5s.
4.  **Reset Physics:** Disable `collision_shape` temporarily or use `set_deferred` to prevent the player from getting "stuck" inside the wall during the move.

## Performance & Optimization
- **Layer Mask:** Set scanner rays to only check the Environment layer (Layer 2 in this project).
- **Update Frequency:** Only enable rays when the player is moving or when a "Parkour" button (e.g., Space) is pressed to save CPU.
- **IK Foot Placement:** Use `SkeletonIK3D` or `RayCasts` at the feet to adjust bone positions so the character actually steps *on* the stairs rather than sliding up them.

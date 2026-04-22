# 3rd Person Player Setup (Godot 4)

Technical standard for setting up a 3rd person CharacterBody3D with a collision-aware SpringArm camera.

## Node Hierarchy
Decoupling horizontal and vertical rotation prevents "gimbal lock" and ensures a smoother feel.

- **CharacterBody3D** (Root)
    - **CollisionShape3D** (Capsule)
    - **Visuals** (MeshInstance3D or Armature) -> **Must face -Z**
    - **CameraPivot** (Node3D) -> **Position: (0, 1.8, 0)**
        - **SpringArm3D** -> **Rotation.x: -15 to -20 deg** (Initial tilt)
            - **Camera3D** -> **Transform: Reset to (0,0,0)**

## The -Z Convention
- **Forward:** -Z
- **Backward:** +Z
- **Right:** +X
- **Left:** -X
- **Up:** +Y

Ensure your player model faces the **Blue Arrow** (-Z) in the editor's local space.

## SpringArm3D Configuration
- **Spring Length:** 3.0 to 5.0 meters (Standard: 4.0m).
- **Margin:** 0.1 to 0.5 (prevents camera from being exactly flush with walls).
- **Collision Mask:** **IMPORTANT.** Set to **Layer 2**. 
- **Layer Separation Rule:** To prevent the character from disappearing when the camera hits their head:
    1. Keep the **Player** on **Layer 1**.
    2. Set the **SpringArm Mask** to **Layer 2**.
    3. Put **Environment/Floor** on **BOTH Layer 1 and 2** (Binary value: 3). This allows the player to stand on it (L1) and the camera to hit it (L2) while the camera safely ignores the player (L1).

## Aim Down Sights (ADS) Zoom
Professional 3rd-person feel is achieved by interpolating FOV, camera distance, and shoulder offset simultaneously.

### Recommended Parameters:
- **Default FOV:** 75.0 -> **ADS FOV:** 50.0
- **Default Spring Length:** 2.5 -> **ADS Spring Length:** 1.5
- **Default h_offset:** 0.6 -> **ADS h_offset:** 0.75

### Implementation Pattern (Tweens):
Using `create_tween().set_parallel(true)` allows for a snappy, simultaneous transition.
```gdscript
func _toggle_ads(aiming: bool) -> void:
    var target_fov = ADS_FOV if aiming else DEFAULT_FOV
    var target_len = ADS_SPRING_LENGTH if aiming else DEFAULT_SPRING_LENGTH
    var target_off = ADS_H_OFFSET if aiming else DEFAULT_H_OFFSET
    
    var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
    tween.tween_property(camera, "fov", target_fov, 0.2)
    tween.tween_property(spring_arm, "spring_length", target_len, 0.2)
    tween.tween_property(camera, "h_offset", target_off, 0.2)
```

## Input & Rotation Logic
- **Horizontal (Y-axis):** Rotate the **Root CharacterBody3D** (for shooter-style lock).
- **Vertical (X-axis):** Rotate the `SpringArm3D` node and **clamp** the rotation between roughly -70 and 70 degrees.

### Camera-Relative Movement
To move where the camera is looking:
```gdscript
var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
# Convert input to 3D space
var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
# If root is locked to camera, this matches the camera direction automatically
```

## Troubleshooting: Facing the Face at Spawn
If your camera starts by looking at your character's face:
1. **Option A (Root Fix):** Rotate the root `CharacterBody3D` node 180 degrees.
2. **Option B (Pivot Fix):** Rotate the `SpringArmOffset` (Pivot) until the camera is behind the back.
3. **Check Visuals:** Ensure the character mesh itself is facing -Z (local forward) inside its own scene.


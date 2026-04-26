# Godot Interaction Patterns

## 1. Character Setup
Characters (Players/NPCs) should have a `Scanner` Node3D containing:
- `ForwardRay` (RayCast3D): Precise interaction (Length: 2.0-3.0m).
- `ProximityArea` (Area3D): Optional fallback for items at feet.

## 2. Interactable Interface
Any object that can be interacted with MUST implement:
```gdscript
func interact(player: Node3D) -> void:
    # Logic for interaction
```

## 3. Weapon System Integration
For weapon drop/pickup and swapping:
- **Drop**: Instantiate the `current_world_item_scene`, set transform, apply impulse, hide held model.
- **Pickup**: 
    1. Clear existing visuals in the player's `weapon_root` (skip Marker3Ds).
    2. Instantiate the `weapon_visual_scene` from the world item.
    3. Store the world item's own scene path for future dropping.
    4. `queue_free()` the world item.
- **Swapping**: Use `WeaponResource` to store stats and model data. Swap models and update `AnimationTree` libraries dynamically.

## 4. GLB Visual Wrapping
Always wrap `.glb` or `.gltf` imports in a `.tscn` file. This allows:
- Applying consistent `rotation` or `scale` offsets.
- Adding `Muzzle` or `Flash` markers in the editor.
- Overriding materials without affecting the source file.

## 4. Vehicle System (Possession Flow)
- **Entry**: 
    1. Parent Player to Vehicle `Seat`.
    2. Disable Player `process_mode` and `visibility`.
    3. Activate Vehicle script processing and Camera authority.
- **Exit**: Spawn Player at `ExitPoint` marker and re-enable.

## 5. Input Defaults
- **Interact**: 'E' (Key/Action)
- **Drop**: 'G' (Key/Action)
- **Alt Interact**: 'F' (Key/Action)

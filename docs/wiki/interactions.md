# Interaction System Architecture

This document outlines the professional standards for interaction systems in the BanditandTavious project, optimized for Godot 4.3+ multiplayer.

## 1. Core Component Pattern
Instead of hardcoding interaction logic into the player, use a **composition-based** approach.

### InteractionComponent (Area3D)
Attached to any interactable object (Weapons, Vehicles, NPCs).
- **Collision Layer**: 1 (Interactables)
- **Properties**:
    - `action_name`: String (e.g., "Enter Vehicle", "Pick up Pistol")
    - `interaction_type`: Enum (WEAPON, VEHICLE, NPC, STATIC)
- **Method**: `interact(player: Node3D)` triggers the specific logic for that object.

### Interactor (RayCast3D)
Attached to the Player/NPC `Scanner` or Camera.
- **Logic**: In `_physics_process`, check `is_colliding()`. If the hit object is an `InteractionComponent`, cache it as the `current_interactable`.
- **UI**: Emit a signal or update a Label3D to show the `action_name`.

## 2. Weapon Swapping & Inventory
Weapons should be handled as **Resources** to decouple data from visuals.

### WeaponResource (Resource)
- `weapon_name`: String
- `model_scene`: PackedScene (Visuals only)
- `stats`: Damage, Range, FireRate
- `animation_library`: AnimationLibrary (Specific reload/draw/fire clips)

### WeaponManager (Node3D)
A child of the Player (under `RightHand` bone).
- Manages an `Array[WeaponResource]` inventory.
- **Weapon Swap Logic**:
    1. Call `queue_free()` on current visual model.
    2. Instantiate `new_weapon.model_scene`.
    3. Update `AnimationTree` with the new weapon's animation library.
    4. Sync `current_weapon_index` via `MultiplayerSynchronizer`.

## 3. Vehicle Interaction
Vehicles use a **Possession/Depossession** flow.

### Entry Flow
1. **Validation**: Check if seat is empty.
2. **Parenting**: Reparent the Player to the Vehicle's `Seat` node or a hidden `Passengers` container.
3. **State Change**:
    - Set Player `process_mode = PROCESS_MODE_DISABLED`.
    - Set Player `visible = false` (or play "entering" animation).
4. **Control Transfer**: 
    - Enable the Vehicle's processing.
    - Transfer `MultiplayerAuthority` or route inputs from the Player to the Vehicle controller.
5. **Camera**: Smoothly lerp or snap the `Camera3D` to the Vehicle's `SpringArm3D`.

### Exit Flow
1. **Placement**: Spawn the Player at a designated `ExitPoint` marker (ensure no collision).
2. **Reset**: Enable Player visibility and processing.
3. **Clean up**: Disable Vehicle processing if no driver remains.

## 4. NPC Interaction
- Use the same `InteractionComponent`.
- Trigger a **Blackboard** update or a **Dialogue UI** overlay.
- NPC should enter an "Interaction" state (rotate toward player, stop current task).

## 5. Common Pitfalls
- **Collision Filtering**: Ensure `Scanner` rays don't hit the player's own capsule. Use `collision_mask` specifically for interactables.
- **Parenting vs. Logic**: Reparenting nodes in multiplayer can be complex; preferred method is visibility toggling and state synchronization.
- **Dead Locks**: Always ensure an `ExitPoint` exists for vehicles, or players may get stuck inside geometry.

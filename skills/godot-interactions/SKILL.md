---
name: godot-interactions
description: Implementation of interaction systems for Godot 4 characters, including weapon drop/pickup, world items, vehicles, and NPCs. Use when adding interactable objects or expanding player/NPC capabilities to manipulate items in the world.
---

# Godot Interactions Skill

This skill provides a standardized workflow for adding interactions to the BanditandTavious project.

## Core Interface
Objects that can be interacted with must implement a `func interact(player: Node3D) -> void` method.

## Workflows

### 1. Adding a new Interactable Item
1. Create a scene for the world item (usually `RigidBody3D` or `Area3D`).
2. Add a `CollisionShape3D` to define the interaction volume.
3. Attach a script and implement the `interact(player)` method.
4. (Optional) Define properties like `item_id` or `quantity`.

### 2. Updating a Character for Interactions
1. Ensure the character has a `Scanner` child node.
2. Add a `ForwardRay` (RayCast3D) to the Scanner.
3. Update the character script to handle `_check_interaction()` triggered by the `interact` action (Default: 'E').
4. Implement a proximity fallback using `get_world_3d().direct_space_state.intersect_shape()` if needed.

### 3. Implementing Weapon Drop/Pickup
Refer to the Weapon System Pattern:
- **Drop (G)**: Instantiate world item -> Set global transform -> Apply impulse -> Hide held weapon.
- **Pickup (E)**: Identify item -> Call player pickup method -> Queue free world item.

## Reference Material
- See [patterns.md](references/patterns.md) for detailed implementation standards.
- Reusable script: [interaction_world_item.gd](scripts/interaction_world_item.gd)

## Interaction Verification
- Verify the object is on a collision layer reachable by the player's raycast mask.
- Confirm `enabled = true` on all raycasts.
- Test interaction from multiple angles to ensure collision volumes are sufficient.

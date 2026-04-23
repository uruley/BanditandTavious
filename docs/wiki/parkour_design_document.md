# Godot 4 3D Parkour System Architecture

## Overview
This document outlines the architectural blueprint and implementation standards for the advanced 3D parkour system using Godot 4. The goal is to create a fluid, responsive, and momentum-based traversal system anchored by a Node-based Finite State Machine (FSM).

## Core Architecture: Node-Based Finite State Machine (FSM)
The player controller (`CharacterBody3D`) will delegate movement logic to a hierarchical State Machine. This prevents tangled `if/else` logic and ensures only one traversal mode is active at any given time.

### Structure
- **Player (CharacterBody3D)**
  - **StateMachine (Node)** -> Manages transitions and the active state.
    - **Idle (Node)** -> Base state when stationary.
    - **Run (Node)** -> Standard movement.
    - **Jump (Node)** -> Airborne state originating from the floor.
    - **Fall (Node)** -> Airborne state when moving downwards.
    - **WallRun (Node)** -> Moving horizontally along a vertical surface.
    - **WallSlide (Node)** -> Sliding down a vertical surface.
    - **WallJump (Node)** -> Airborne state originating from a wall.
    - **Slide (Node)** -> Crouched, high-momentum ground movement.
    - **Vault/Mantle (Node)** -> Procedural ledge climbing.

### State Interface
Each state extends a virtual base `State` script with the following core functions:
- `enter()`: Initialization upon activation (e.g., setting animations, adjusting FOV).
- `exit()`: Cleanup before transitioning to a new state.
- `handle_input(event)`: Processes unhandled input.
- `update(delta)`: Frame-based logic (e.g., visual "juice").
- `physics_update(delta)`: Movement and collision logic.

## Key Mechanics Implementation

### Wall Interaction (Running, Sliding, Jumping)
- **Detection:** Utilize `is_on_wall_only()` to verify contact with a wall while airborne.
- **Wall Running:** Project the character's forward input direction onto the wall's tangent to move parallel. Reduce gravity to allow a slight "sink".
- **Wall Sliding:** Significantly reduce downward acceleration to simulate friction.
- **Wall Jumping:** Redirect kinetic energy away from the surface using the wall's normal (`get_wall_normal()`).

### Vaulting & Mantling (Procedural Movement)
- **Detection Model:** Use a multi-ShapeCast3D setup:
  - *Lower Cast:* Detects the presence and distance of the obstacle.
  - *Middle Cast:* Determines if the obstacle is vaultable (waist-high) or climbable (chest-high).
  - *Upper Cast:* Checks for clear space above the obstacle.
  - *Downward Cast:* Finds the exact landing coordinates on the top surface.
- **Procedural Execution:** When triggered, disable standard physics velocity. Use a `Tween` to move the `global_position` in two phases: vertical lift, then horizontal placement.

### Sliding
- **Collision Adjustment:** Do not scale the `CollisionShape3D` node. Instead, modify the `height` property of the underlying `CapsuleShape3D` resource and adjust its vertical offset to remain flush with the floor.
- **Slope Integration:** Use `get_floor_normal()` to detect downward slopes. Convert friction into a "gravity assist" to accelerate the player down steep hills.

## Visual Polish ("Juice")
- **Camera Tilt:** Use a `Tween` or `lerp()` to rotate the camera's Z-axis (roll) slightly away from the wall during a WallRun.
- **Dynamic FOV:** Slightly increase the camera's Field of View during sprints and slides to enhance the sensation of speed.
- **Camera Shake:** Implement a subtle "bob" or shake upon heavy landings.

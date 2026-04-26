# Bandit Model Testing

The Bandit model has been rigged to the Lyra skeleton and is ready for testing.

## Files Created
- **Rigged Model**: `res://assets/characters/player/Bandit/Bandit_Rigged.glb`
- **Visual Wrapper**: `res://assets/characters/player/Bandit/Bandit_Visual.tscn`
- **Player Scene**: `res://level/scenes/bandit_player.tscn`
- **Test Level**: `res://level/scenes/bandit_test_level.tscn`

## How to Test
1. Open `res://level/scenes/bandit_test_level.tscn` in Godot.
2. Press **F6** to run the scene.
3. Use **WASD** to move, **Shift** to sprint, **Ctrl** to crouch, and **Space** to jump.
4. Observe the mesh deformations and ensure the animations from the Lyra/Bachtavious set are playing correctly.

## Known Details
- The Bandit mesh was scaled by **1.68x** to match the Lyra skeleton height (1.68m).
- Duplicate vertices were merged (33,193) to enable successful bone heat weighting.
- The `bandit_player.tscn` uses `bachtavious_multiplayer_player.gd` and dynamically loads locomotion/parkour libraries.

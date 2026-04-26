# Modular Weapon System

This domain covers the data-driven architecture used for weapons in BanditandTavious. It is based on the "Modular Weapon System with Custom Resources" pattern (StayAtHomeDev).

## Architecture Overview

The system decouples weapon logic from visual representation and statistics using Godot's **Custom Resources**.

### 1. WeaponResource (`.tres`)
A custom resource (`weapon_resource.gd`) that defines all unique properties of a weapon:
- **Visuals:** `weapon_visuals` (PackedScene).
- **Transforms:** `position_offset`, `rotation_offset`, and `scale_offset` for hand alignment.
- **Muzzle:** `muzzle_position_offset` and `muzzle_rotation_offset` for projectile/VFX alignment.
- **Stats:** `damage`, `fire_rate`, `mag_size`, `is_automatic`.
- **Assets:** `fire_sound`, `muzzle_vfx`, `projectile_scene`.

### 2. WeaponMaster Scene
A single, reusable scene (`WeaponMaster.tscn`) that acts as the runtime container for any weapon.
- It instantiates the `weapon_visuals` from the resource.
- It manages the firing cooldown using a `Timer`.
- It emits a `fired` signal and handles visual/audio feedback.
- It uses `@tool` to allow for instant visual alignment in the Godot Editor.

## Workflow: Creating a New Weapon

1. **Prepare Visuals:** Create a `.tscn` or use a `.glb` for the weapon model.
2. **Create Resource:** Right-click in FileSystem -> **Create -> Resource -> WeaponResource**.
3. **Configure:**
   - Assign the visual scene to `Weapon Visuals`.
   - Set the `Fire Rate` and `Damage`.
   - Adjust `Position Offset` and `Rotation Offset` until the weapon aligns correctly with the character's hand in the Inspector preview.
4. **Save:** Save as `res://level/data/weapons/your_weapon.tres`.

## Integration

### Player Controller
The player controller (`character_body_3d.gd`) manages the active weapon:
- It holds a reference to a `WeaponResource` (e.g., `current_weapon`).
- It has a `WeaponMaster` node as a child (usually attached to a `BoneAttachment3D` for the hand).
- On `_ready` or when equipping, it assigns the resource: `weapon_master.weapon_resource = current_weapon`.

### Firing Logic
```gdscript
if input_shoot:
    if weapon_master.fire():
        # Play player-side animations (e.g., recoil, muzzle flash)
        pass
```

## Alignment & Offsets
One of the key benefits of this system is solving "misaligned weapons". Instead of hardcoding offsets in the character script or model, they are stored in the `WeaponResource`. This allows each weapon to be perfectly tuned without affecting others.

There are two separate transforms:
- **Character socket transform:** `WeaponMaster` under the character's `RightHand` bone. Tune this once per character rig/animation set.
- **Weapon visual transform:** `position_offset`, `rotation_offset`, and `scale_offset` on each `WeaponResource`. Tune this once per weapon.

For Bachtavious/Lyra, `WeaponMaster` is parented under `Bachtavious/Armature/Skeleton3D/RightHand`. `level/scenes/lyra_player_clean.tscn` now uses the same proven hand-socket transform as `Bachtavious.tscn`, so the remaining per-gun alignment should happen in the resource.

### Calibration Workflow

Use `res://level/scenes/weapons/WeaponCalibration.tscn`.

1. Open `WeaponCalibration.tscn`.
2. On the root `WeaponCalibration` node, set `weapon_resource` to the pistol/rifle resource being tuned.
3. Set `animation_name` to a relevant pose such as `Pistol_Aim_Neutral`, `Pistol_Shoot`, or `Pistol_Reload`.
4. Adjust `animation_pose` to scrub to the frame where grip alignment matters most.
5. Open the selected `.tres` weapon resource and tune:
   - `position_offset`
   - `rotation_offset`
   - `scale_offset`
   - `muzzle_position_offset`
   - `muzzle_rotation_offset`
6. Do not move the character, the right-hand bone attachment, or the weapon visual scene just to fix one weapon. Per-gun adjustments belong in that gun's `WeaponResource`.

`WeaponMaster.gd` is a `@tool` script and now auto-applies resource offset changes in the editor, so resource edits should update the preview without needing to run the game.

## Current Integration State

- `level/scenes/lyrasandbox.tscn` currently uses `level/scenes/lyra_player_clean.tscn`, which resolves `WeaponMaster` from the instanced `Bachtavious` hand path.
- The primary pickup scenes are now `res://level/scenes/weapons/PistolPickup.tscn` and `res://level/scenes/weapons/RiflePickup.tscn`.
- `res://level/scenes/weapons/WeaponPickup.tscn` is the generic configurable pickup scene. It is an `Area3D` with one exported `WeaponResource`, a collision shape, and a `VisualRoot`.
- `level/scripts/weapons/weapon_pickup.gd` owns pickup detection. If `auto_pickup` is true, `body_entered` tries to equip. `interact(player)` always tries to equip, so player scripts can support explicit pickup keys.
- `consume_on_pickup` only controls whether the pickup queues itself for deletion after a successful equip. It does not mean auto-pickup.
- `level/scripts/weapons/weapon_inventory_component.gd` is the player-owned pickup/equip spine. It owns `current_weapon`, resolves `WeaponMaster`, equips resources, emits equip/drop signals, and spawns `WeaponPickup.tscn` when dropping.
- `WeaponMaster.gd` applies per-weapon visual and muzzle offsets from `WeaponResource` whenever a weapon is equipped.
- `bachtavious_multiplayer_player.gd` now creates or resolves a `WeaponInventory` child and delegates pickup/drop to the component. Press `E` to interact with nearby pickups and `G` to drop the current weapon. Its old direct pickup/drop path remains only as fallback compatibility.
- `PistolPickup.tscn` and `RiflePickup.tscn` now set `auto_pickup = false`, so placed sandbox weapons require explicit `E` pickup.
- Dropped weapons are configured as pickups with `auto_pickup = false`, preventing instant re-pickup on the next physics frame.
- The Bachtavious controller checks direct ray hits, physics overlap, then nearby nodes in the `weapon_pickups` group within `PICKUP_INTERACTION_RADIUS`. This keeps `E` pickup usable even when collision debug overlap is hard to line up exactly.
- `level/scenes/lyrasandbox.tscn` no longer places the old `WeaponWorldItem` / `SilverWeaponWorldItem` instances for the active rifle/pistol pickups. The old scene-instance overrides that set pickup resources to `null` have been removed from the Lyra sandbox weapon placements.
- `level/scenes/lyrasandbox.tscn` also no longer places raw `A3500X_silver_rigged` or standalone `SilverRifle` visual nodes near the pickups. Those were visible guns without pickup behavior and made it easy to walk up to the wrong object.
- `WeaponWorldItem.tscn` and `SilverWeaponWorldItem.tscn` are legacy compatibility scenes, not the source of truth for new placed weapons.
- Raw visual scenes such as `SilverRifle.tscn` or imported GLBs are not pickup objects. Drop the pickup scene, not the weapon visual scene.
- Projectile spawning still lives in the player controller, but it now reads `WeaponResource.projectile_scene` when provided and falls back to `simple_projectile.tscn`.

## Rebuild Implementation State

Implementation date: 2026-04-25.

The first rebuilt pickup/equip vertical slice is implemented and headless-verified for the Lyra/Bachtavious path.

Implemented:
- `WeaponPickup.tscn` plus `weapon_pickup.gd`.
- `WeaponInventoryComponent` plus Bachtavious controller bridge.
- Per-weapon hand/muzzle alignment fields in `WeaponResource`.
- Editor-refreshing `WeaponMaster.gd` alignment preview.
- `WeaponCalibration.tscn` root script for tuning weapons against Bachtavious pistol animations.
- `PistolPickup.tscn` and `RiflePickup.tscn` as the concrete scenes to place in levels.
- `WeaponPickupTest.tscn`, which proves a generic `CharacterBody3D` entering a pickup equips `pistol.tres`.
- `WeaponPickupLyraBridgeTest.tscn`, which proves the actual `lyra_player_clean.tscn` Bachtavious player entering `RiflePickup.tscn` equips `rifle.tres`.
- `lyrasandbox.tscn` weapon placements now point at the new pickup scenes.
- Explicit `E` pickup and `G` drop behavior for the Lyra/Bachtavious path.
- Enlarged and raised the base `WeaponPickup.tscn` collision sphere so the debug shape better surrounds the visible pickup.

Verification:
- `WeaponPickupTest.tscn` logs `WEAPON_PICKUP_TEST PASS`.
- `WeaponPickupLyraBridgeTest.tscn` logs `WEAPON_PICKUP_LYRA_BRIDGE_TEST PASS` after confirming `auto_pickup=false` does not equip on overlap, explicit interaction can equip a nearby non-overlapping rifle pickup, and dropping spawns a non-auto pickup.
- `lyrasandbox.tscn` loads headless with the new placed pickup scenes and no new weapon parse/runtime errors.
- Full visual verification remains pending because no screenshot or player recording has been captured for the live walk-up pickup behavior.

## Research-Backed Rebuild Decision

Decision date: 2026-04-25.

The current implementation should not be patched further as the primary path. Keep the useful assets and data model, but rebuild the pickup/equip spine as a small vertical slice.

Keep:
- `WeaponResource` as the weapon data definition.
- Weapon visual scenes such as `BlackPistol.tscn` and `SilverRifle.tscn`.
- The `WeaponMaster` concept as the held-weapon runtime container, after validating it in isolation.

Replace:
- The current world-item integration path (`WeaponWorldItem.tscn`, `SilverWeaponWorldItem.tscn`, and `weapon_world_item.gd`) as the source of truth.
- Branch-specific pickup methods embedded directly in multiple player controllers.
- Level instances that override pickup properties directly in large `.tscn` files.
- Mixed pickup detection paths where raycasts, shape queries, and pickup-owned areas all race to call the same method.

Why:
- Godot's `Area3D` model is enough for a basic pickup: a monitored area emits `body_entered` when a `PhysicsBody3D` enters, so a simple pickup should not require multiple fallback systems.
- Collision layers and masks are directional. An object only detects another object when the other object is on a layer the first object scans, so pickup behavior should define one clear `player` layer and one clear `pickup`/`interaction` layer.
- Godot's scene-organization guidance warns that reusable scenes break when they depend on external node paths or environment details. The current setup has that failure mode: the same conceptual pickup behaves differently depending on base scene, level instance overrides, and player branch.
- Signals are intended to keep objects reacting without hard references. A pickup should emit or call a narrow interface once, not know about every player branch.

Current failure findings:
- `level/scenes/lyrasandbox.tscn` contains placed `SilverWeaponWorldItem` instances that override the inherited scene defaults with `weapon_resource = null`, `auto_pickup = null`, `pickup_delay = null`, and root collision layer/mask `1/1`. These overrides defeat the base pickup scene and explain why the latest pickup patch did not affect the actual placed rifle pickups.
- The project main path remains `Sandbox.tscn` -> `player.tscn` -> `player.gd`, and that stock player does not implement the modular weapon pickup API. The Lyra/Bachtavious weapon branch is still an alternate sandbox path.
- The same concept is split across `character_body_3d.gd`, `bachtavious_multiplayer_player.gd`, `player.gd`, `WeaponWorldItem.tscn`, `SilverWeaponWorldItem.tscn`, and large per-level scene overrides. That is too much surface area for the first requirement: "walk up and pick up one object."

Target rebuilt spine:
1. `WeaponPickup.tscn`: root `Area3D`, child `CollisionShape3D`, child `VisualRoot`, script exports exactly one `WeaponResource`.
2. `weapon_pickup.gd`: on `body_entered`, find a `WeaponInventoryComponent` on the body or its children, then call `try_pick_up(resource)`. On success, queue-free the pickup.
3. `weapon_inventory_component.gd`: player-owned component with `equip_weapon(resource)`, `drop_current_weapon()`, and `has_weapon()`; it owns `current_weapon` and the reference to `WeaponMaster`.
4. Player scripts call the component for shooting/drop input. Player scripts should not each reimplement pickup logic.
5. `WeaponPickupTest.tscn`: isolated test scene with one simple player body, one pickup, and a runtime assertion/log that pickup happened. This must pass before integrating into `lyrasandbox.tscn` or `Sandbox.tscn`.

First rebuild milestone:
- Proved one local test scene where walking a `CharacterBody3D` into `WeaponPickup.tscn` equips `pistol.tres`, hides/removes the pickup, and updates `WeaponMaster`.
- Replaced the placed weapon instances in `lyrasandbox.tscn`.
- Only after the Lyra path works, decide whether to migrate `Sandbox.tscn` to the new player branch or add the component to the stock `player.tscn`.

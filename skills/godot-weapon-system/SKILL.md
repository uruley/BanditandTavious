---
name: godot-weapon-system
description: Build, debug, and maintain the BanditandTavious Modular Weapon System in Godot 4, including WeaponResource data, WeaponMaster held visuals, WeaponPickup level objects, WeaponInventoryComponent equip/drop flow, Bachtavious/Lyra integration, and per-gun hand/muzzle alignment.
---

# Godot Weapon System

Use this skill whenever working on pickups, equipped weapons, firing data, dropped weapons, gun visuals, or weapon alignment in `BanditandTavious`.

The project weapon system is called the **Modular Weapon System**. Its active runtime spine is:

`WeaponPickup -> WeaponInventoryComponent -> WeaponMaster -> WeaponResource`

## Required Context

Before changing weapon code or scenes:

1. Read `docs/ai/memory.md`, `docs/ai/current-state.md`, `docs/ai/lessons.md`, and `docs/ai/session-notes.md`.
2. Read `docs/wiki/weapon_system.md` for the current architecture and known drift.
3. Confirm the actual target scene from source. The Lyra weapon sandbox is `res://level/scenes/lyrasandbox.tscn`, which uses `res://level/scenes/lyra_player_clean.tscn`.
4. Verify serialized `.tscn` files when Godot MCP/editor state disagrees with file contents.

## Source Of Truth

Active scenes:

- `res://level/scenes/weapons/WeaponPickup.tscn`: generic configurable pickup scene.
- `res://level/scenes/weapons/PistolPickup.tscn`: placed pistol pickup.
- `res://level/scenes/weapons/RiflePickup.tscn`: placed rifle pickup.
- `res://level/scenes/weapons/WeaponMaster.tscn`: held-weapon runtime/editor container.
- `res://level/scenes/weapons/WeaponCalibration.tscn`: visual alignment preview scene.

Active scripts:

- `res://level/scripts/weapons/weapon_resource.gd`: weapon data resource.
- `res://level/scripts/weapons/weapon_master.gd`: held weapon visual, muzzle, fire cooldown, and editor preview.
- `res://level/scripts/weapons/weapon_pickup.gd`: pickup Area3D behavior.
- `res://level/scripts/weapons/weapon_inventory_component.gd`: player-owned equip/drop component.
- `res://level/scripts/weapons/weapon_alignment_calibration.gd`: alignment preview helper.
- `res://level/scripts/bachtavious_multiplayer_player.gd`: Lyra/Bachtavious player bridge for `E` pickup and `G` drop.

Active resources:

- `res://level/data/weapons/pistol.tres`
- `res://level/data/weapons/rifle.tres`

Legacy compatibility scenes:

- `res://WeaponWorldItem.tscn`
- `res://SilverWeaponWorldItem.tscn`

Do not use legacy world-item scenes as the source of truth for new placed weapons. Do not place raw visual scenes such as `SilverRifle.tscn`, `BlackPistol.tscn`, or imported `.glb` weapon models directly in a level when the object needs to be interactable. Place `PistolPickup.tscn`, `RiflePickup.tscn`, or a configured instance of `WeaponPickup.tscn`.

## Architecture

### WeaponResource

`WeaponResource` is the weapon's data definition. It owns:

- visual scene: `weapon_visuals`
- hand alignment: `position_offset`, `rotation_offset`, `scale_offset`
- muzzle alignment: `muzzle_position_offset`, `muzzle_rotation_offset`
- stats: damage, fire rate, magazine size, automatic flag
- effects: fire sound, muzzle VFX, projectile scene

Per-gun visual problems belong in the resource, not in the player controller or skeleton.

### WeaponMaster

`WeaponMaster.tscn` is the held-weapon container attached to the character hand/socket. `weapon_master.gd` is a `@tool` script and should refresh visuals in the editor when the assigned resource changes.

Use this split:

- Move `WeaponMaster` only when the character rig's base hand socket is wrong.
- Move resource offsets when one gun is wrong.

### WeaponPickup

`WeaponPickup.tscn` is a root `Area3D` with a collision shape and `VisualRoot`. Its script exports one `WeaponResource`.

Important flags:

- `auto_pickup`: if true, overlap can equip automatically.
- `consume_on_pickup`: if true, delete the pickup after a successful equip.

Keep these meanings separate. `consume_on_pickup = false` does not mean "press E to pick up"; `auto_pickup = false` does.

### WeaponInventoryComponent

`WeaponInventoryComponent` is owned by the player. It should be the only place that owns `current_weapon`, equips through `WeaponMaster`, and spawns dropped pickup scenes.

Player scripts may route input into the component, but should not each reimplement pickup/equip/drop rules.

## Lyra/Bachtavious Rules

In the active Lyra path:

- `E` interacts with nearby pickups.
- `G` drops the current weapon.
- placed `PistolPickup.tscn` and `RiflePickup.tscn` use `auto_pickup = false`.
- dropped weapons should also use `auto_pickup = false` so the player does not instantly re-pick them.
- the Bachtavious controller checks direct ray hits, physics overlap, then nearby nodes in the `weapon_pickups` group.

If pickup interaction fails, check in this order:

1. Is the visible object actually a `WeaponPickup` scene, not a raw weapon visual?
2. Is the pickup in the `weapon_pickups` group?
3. Does it have a non-null `weapon_resource`?
4. Does the player have or create `WeaponInventoryComponent`?
5. Can the component resolve `WeaponMaster`?
6. Are collision layers/masks and the pickup shape large enough to be reached?
7. Does the serialized level instance override inherited pickup properties to `null`?

## Alignment Workflow

Use `res://level/scenes/weapons/WeaponCalibration.tscn` for tuning.

1. Open `WeaponCalibration.tscn`.
2. On the root node, assign the target `WeaponResource`.
3. Preview a relevant animation such as `Pistol_Aim_Neutral`, `Pistol_Shoot`, or `Pistol_Reload`.
4. Tune these fields on the resource:
   - `position_offset`
   - `rotation_offset`
   - `scale_offset`
   - `muzzle_position_offset`
   - `muzzle_rotation_offset`
5. Do not move the character, armature, right-hand bone, or weapon visual scene to fix one weapon.

If a gun is backwards when equipped, first adjust that resource's `rotation_offset`. For current SilverRifle-based resources, a Y rotation of `-180` degrees has been used to correct orientation.

## Creating A New Weapon

1. Create or import the weapon visual scene.
2. Create a `WeaponResource` under `res://level/data/weapons/`.
3. Assign the visual scene to `weapon_visuals`.
4. Set stats and effects.
5. Tune hand and muzzle offsets in `WeaponCalibration.tscn`.
6. Create a pickup by instancing `WeaponPickup.tscn` or duplicating an existing concrete pickup scene.
7. Assign the new resource to the pickup.
8. Place the pickup scene in the target level.

## Verification

Minimum checks before calling weapon work complete:

1. Validate or open changed scripts/scenes without parse errors.
2. Run the isolated weapon tests when pickup/equip/drop behavior changes:
   - `res://level/scenes/weapons/WeaponPickupTest.tscn`
   - `res://level/scenes/weapons/WeaponPickupLyraBridgeTest.tscn`
3. Load `res://level/scenes/lyrasandbox.tscn` after scene edits.
4. For gameplay changes, perform a live editor walk-up test when possible:
   - walk near `PistolPickup.tscn` or `RiflePickup.tscn`
   - press `E`
   - confirm the weapon appears in hand
   - press `G`
   - confirm a non-auto pickup is dropped
5. Capture screenshot/video evidence for a full green light. Headless-only verification is partial for visual alignment.

Use an explicit repo-local `--log-file` for Godot CLI headless runs on this machine.

## Cleanup Rules

Legacy root files are not active source of truth, but deleting them is a separate destructive cleanup task. Do not remove `WeaponWorldItem.tscn`, `SilverWeaponWorldItem.tscn`, or their scripts unless the user explicitly approves that cleanup.

When durable weapon workflow changes, update:

- this skill
- `docs/wiki/weapon_system.md`
- `docs/ai/memory.md` or `docs/ai/current-state.md` when the change affects project direction or active state

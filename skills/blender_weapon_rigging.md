# Blender Weapon Rigging & Texturing Skill

Use this workflow to rig and texture weapons for Godot 4.

## Core Mandates
1. **Scale**: Always scale to real-world dimensions (e.g., 0.2m for pistols).
2. **Orientation**: Godot uses **-Z Forward** and **Y Up**. Rotate the mesh to match this *before* parenting.
3. **Safe Parenting**: Use `bpy.ops.object.parent_set(type='BONE')` in POSE mode to keep the mesh from "exploding" or jumping to the origin.
4. **Materials**: PBR materials must be created and textures linked to the Principled BSDF node for them to export in the GLB.

## The Checklist

### 1. Preparation
- [ ] Import original mesh (FBX/OBJ).
- [ ] Take screenshots (Front, Side, Top) to verify orientation.
- [ ] Calculate scale factor (Target Size / Current Size).

### 2. Mesh Cleanup & Scaling
- [ ] Apply `Scale`, `Location`, and `Rotation` to all meshes.
- [ ] Rotate to align with Godot convention (-Z forward).
- [ ] Re-apply `Rotation`.

### 3. Texturing (PBR)
- [ ] Create a new Material.
- [ ] Link `Base Color` (sRGB).
- [ ] Link `Metallic` (Non-Color).
- [ ] Link `Roughness` (Non-Color).
- [ ] Link `Normal Map` (Non-Color) through a Normal Map node.
- [ ] Assign materials to meshes based on name patterns (e.g., "mag" -> Magazine Material).

### 4. Rigging
- [ ] Add Armature.
- [ ] Create bones with logical names: `Body`, `Slide`, `Trigger`, `Magazine`, `Muzzle`.
- [ ] Parent bones correctly (`Slide` -> `Body`, etc.).
- [ ] **Muzzle Placement**: Position the `Muzzle` bone tip at the exact point where projectiles should spawn.

### 5. Parenting
- [ ] Select Mesh, then Armature.
- [ ] Enter **POSE** mode.
- [ ] Select the target bone.
- [ ] Execute `Parent to Bone`.

### 6. Export
- [ ] Export as **GLB**.
- [ ] Enable `Apply Modifiers`, `Skins`, and `Animations`.

## Automated Script Template
The `tools/rig_pistol.py` script contains the Python implementation of this workflow. Use it as a base for new weapons.

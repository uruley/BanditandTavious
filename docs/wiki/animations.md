# 3D Animation Workflow (Godot 4)

Technical standard for building a scalable, decoupled animation system using the "Source-and-Library" pattern.

## Core Pattern: Source-and-Library
Do not store animations inside character scenes. Instead, build a global library that multiple characters can share.

### 1. Character Model Import
- Format: **glTF 2.0 (.glb)**.
- Goal: Mesh + Skeleton + Materials only.
- Workflow: In the Import dock, set "Import As" to `Scene`.

### 2. Animation Data Import
- Format: **glTF 2.0 or FBX**.
- Goal: Pure animation data (no mesh).
- Workflow: In the Import dock, set "Import As" to **Animation Library**.
- Storage: Save the resulting resource as an external `.res` file (e.g., `res://assets/animations/humanoid_base.res`).

## Retargeting (SkeletonProfileHumanoid)
To share animations between different rigs (e.g., Mixamo to Godot Manny), use a **BoneMap**.

1. Open the character's **Advanced Import Settings**.
2. Select the **Skeleton3D** node.
3. Create a new **BoneMap** and assign the `SkeletonProfileHumanoid` profile.
4. Use **Auto-Map** or the **Mixamo Retargeter Plugin** to link bones.
5. **Silhouette Fix:** If the model is A-Pose, check "Fix Silhouette" to force it into a T-Pose standard.

## Platform Specifics

### Mixamo Workflow
- **Standard:** Download "T-Pose" WITH skin as your base.
- **Animations:** Download all other animations **WITHOUT skin** to save space.
- **In-Place:** Always check "In Place" in Mixamo for locomotion to handle movement via code (`move_and_slide`).

### Blender Workflow
- **NLA Tracks:** You MUST "Push Down" actions into the **NLA Editor** tracks for Godot to recognize multiple animations.
- **Deformation Bones:** Export with "Deformation Bones Only" enabled to keep the rig clean.
- **Transforms:** Always `Apply All Transforms` in Blender before exporting.

## AnimationPlayer Setup
To use your global library:
1. Add an `AnimationPlayer` to your character scene.
2. Click the **Animation** button at the bottom of the editor.
3. Select **Manage Libraries**.
4. **Add/Load** your shared `.res` library.

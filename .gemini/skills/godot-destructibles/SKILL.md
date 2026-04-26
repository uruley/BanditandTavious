---
name: godot-destructibles
description: Create and wire destructible 3D assets for Godot using Blender fracture workflows, shard imports, Godot scene setup, and runtime verification. Use whenever the user wants a destructible prop, pillar, crate, wall, or localized destruction setup, especially for Blender-to-Godot pipelines that can fail on mesh, material, collision, or fractured-scene wiring.
---

# Godot Destructibles

Use this skill for the full destructible-asset pipeline, not just fracture generation.

The job is only complete when:

- the asset is fractured or otherwise authored for destruction
- the Godot scene has a visible mesh
- materials are assigned
- collision exists and is enabled
- the destruction script is attached and configured
- the fractured replacement is linked
- a verification pass confirms the scene is actually usable

## Repo Alignment

- Destruction design guidance lives in `docs/wiki/destruction.md`.
- The existing replacer implementation lives in `res://level/scripts/destructible.gd`.
- If the user asks for selective bullet-vs-rocket wall damage, do not default to a single whole-object replacer. Follow the chunked-wall guidance in `docs/wiki/destruction.md`.

## Workflow

1. Determine the target destruction type.
   - `prop replacer`: single intact object swaps to pre-fractured shards
   - `animated break`: pre-baked fracture animation
   - `localized wall damage`: chunked/cell-based wall, not a single replacer

2. Author or validate the fractured asset in Blender.
   - Use `tools/blender_fracture_tool.py` when possible.
   - Ensure shard names retain the `-rigid` suffix if the importer depends on it.
   - Recenter shard origins for stable rigidbody behavior.
   - Confirm exterior and interior materials are intentional, not left to defaults.

3. Create or update the Godot scene.
   - Root should match the intended behavior, usually `RigidBody3D` with `res://level/scripts/destructible.gd` for replacer-style props.
   - Add a `MeshInstance3D` for the intact visual.
   - Add a `CollisionShape3D` that actually matches the visible mesh.
   - Assign the fractured scene/exported GLB to the destructible script.

4. Verify the serialized scene, not just editor memory.
   - Read the `.tscn` and confirm the critical properties are saved.
   - Do not trust a partially configured live editor state.

5. Verify runtime behavior when the task includes implementation, not just documentation.
   - Trigger damage or destruction.
   - Check logs/errors.
   - Confirm the object breaks the expected way.
   - Prefer the reusable benchmark path when the asset fits the standard projectile-vs-target test setup.

## Mandatory Checklist

Always open `references/checklist.md` before finishing. Treat it as the definition of done.

For automated validation, also open `references/headless-verification.md`.
For preset threshold choices, open `references/benchmark-presets.md`.

The standard reusable benchmark path is:

- scene template: `res://level/scenes/DestructionBenchmark.tscn`
- benchmark script: `res://level/scripts/destruction_benchmark.gd`

Use that benchmark instead of creating one-off test scenes when a destructible can be exercised by:

- instancing the target scene
- launching a projectile from a known marker
- collecting standardized metrics at fixed timestamps

## Required Scene Checks

At minimum, verify these in the `.tscn` or imported scene:

- root node type is correct for the destruction mode
- `MeshInstance3D` exists and has a non-null mesh
- material is intentionally assigned on the intact mesh, not missing by accident
- `CollisionShape3D` exists and is not disabled
- script path is correct
- `fractured_scene` or equivalent exported reference points to a valid asset path

## Failure Patterns To Guard Against

- fractured asset imported, but intact scene has no visible mesh
- mesh exists, but no material is assigned after import/setup
- collision exists in tree, but is disabled
- destructible script is attached, but `fractured_scene` is unset
- shards import as plain meshes instead of rigidbodies
- the object is reported as complete without a runtime hit test when behavior was requested

## Localized Destruction Rule

If the request is about:

- bullets chipping a small area
- rockets making larger holes
- only unsupported wall sections falling

then recommend or build a chunked/cell-based wall system. Do not misapply the single-object replacer pattern to that problem.

## Headless Verification Rule

When destruction behavior needs proof and full visual capture is not practical, run an instrumented headless scene.

Use headless verification to answer:

- did destruction actually trigger
- how many shards spawned
- how far shards spread
- whether shards settled or kept flying
- whether frame timing changed after impact

Important project-specific workaround:

- do not rely on Godot's default CLI logging path on this machine
- always pass an explicit `--log-file` under the repo's `logs/` directory
- the current Godot mono CLI can crash before scene execution if `--log-file` is omitted

Good headless verification output should include:

- destruction triggered: yes/no
- shard count
- at least one spread metric such as max shard distance
- at least one settle metric such as average shard height over time
- basic pre/post impact frame delta or FPS sampling

Headless verification is strong for objective checks, but not a replacement for final visual signoff when appearance matters.

After a benchmark run, prefer parsing the log with:

```powershell
python skills/godot-destructibles/scripts/parse_destruction_metrics.py `
  logs/destructible-sphere-benchmark.log `
  --preset sphere
```

Use threshold flags to turn the benchmark into a simple pass/fail gate.

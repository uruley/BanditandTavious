# Headless Destruction Verification

Use this when you need objective destruction proof without relying entirely on screenshots.

## What Headless Can Prove

- destruction callback actually fired
- intact object was removed or replaced
- shard scene instantiated
- shard count
- shard spread over time
- rough settle behavior
- basic performance deltas

## What Headless Cannot Prove

- whether the destruction looks good
- whether materials look correct to a player
- whether the hole shape reads well visually
- whether the break feels satisfying

Use screenshots or a short visual run for final presentation-quality approval.

## Project-Specific CLI Workaround

On this machine, Godot headless runs can crash before scene execution if the engine tries to use its default CLI log destination.

Always pass an explicit log file:

```powershell
& '<GodotExe>' `
  --headless `
  --log-file '<RepoRoot>\\logs\\my-run.log' `
  --path '<RepoRoot>' `
  --scene 'res://level/scenes/MyDestructionTest.tscn'
```

Observed behavior:

- omitting `--log-file` can trigger a crash while opening `user://logs/godot....log`
- providing `--log-file` under repo `logs/` avoids that crash path

## Recommended Metrics

Minimum:

- destruction triggered
- shard count
- max shard distance from origin
- average shard height at two timestamps
- pre-impact vs post-impact average frame delta

Good timestamp pattern:

- impact + 0.3s
- impact + 1.0s

## Logging Pattern

Prefer machine-readable log lines such as:

```text
DESTRUCTION_METRICS {"label":"t_plus_0_3s","shard_count":12,"max_shard_distance_from_origin":2.06}
```

This makes it easy to grep or parse later.

## Parser Script

Use the bundled parser after the run:

```powershell
python skills/godot-destructibles/scripts/parse_destruction_metrics.py `
  logs/destructible-sphere-benchmark.log `
  --preset sphere
```

Optional threshold flags:

- `--preset sphere|wall|pillar`
- `--min-shards N`
- `--max-spread X`
- `--max-post-delta X`
- `--require-height-drop`
- `--json`

For preset values, see `references/benchmark-presets.md`.

## Standard Benchmark Path

Use the reusable benchmark before inventing an asset-specific harness:

- scene template: `res://level/scenes/DestructionBenchmark.tscn`
- script: `res://level/scripts/destruction_benchmark.gd`

That benchmark instances a target destructible scene, launches a projectile, and emits standardized `DESTRUCTION_METRICS` lines.

## Current Repo Example

The current focused example is:

- scene: `res://level/scenes/DestructibleSphereTest.tscn`
- script: `res://level/scripts/destruction_benchmark.gd`

That harness currently logs:

- whether impact was detected
- shard count
- max shard distance from target origin
- average shard distance from target origin
- average shard height
- pre/post impact average frame delta

## Interpretation Guidance

- shard count too low: fracture import or replacer scene likely misconfigured
- shard count correct but spread too small: impulse may be too weak
- spread too large: impulse may be too strong or cleanup too slow
- average shard height stays high: shards may be floating, colliding poorly, or never settling
- post-impact frame delta spikes hard: shard count, collision complexity, or cleanup settings may need tuning

# Destruction Benchmark Presets

Use parser presets when a destructible fits a common category and you want a fast pass/fail gate.

## Presets

`sphere`

- minimum shards: 8
- maximum spread: 4.0
- maximum post-impact frame delta: 0.02
- requires average shard height to decrease

`wall`

- minimum shards: 4
- maximum spread: 8.0
- maximum post-impact frame delta: 0.025
- does not require average shard height to decrease because wall shards may scatter laterally or remain upright

`pillar`

- minimum shards: 8
- maximum spread: 6.0
- maximum post-impact frame delta: 0.025
- requires average shard height to decrease

## Usage

```powershell
python skills/godot-destructibles/scripts/parse_destruction_metrics.py `
  logs/destructible-sphere-benchmark.log `
  --preset sphere
```

Explicit flags override preset defaults when provided:

```powershell
python skills/godot-destructibles/scripts/parse_destruction_metrics.py `
  logs/destructible-sphere-benchmark.log `
  --preset sphere `
  --max-spread 3.0
```

# AI Metrics Schema

Use newline-delimited JSON (`.jsonl`) so logs can be streamed during headless runs and parsed after a crash.

Every event should include:

```json
{
  "type": "decision",
  "time_sec": 12.5,
  "frame": 720,
  "run_id": "ai_001",
  "scene": "res://level/scenes/lyrasandbox.tscn"
}
```

## Event Types

### `decision`

Emitted whenever an actor chooses or keeps a high-level goal.

Required fields:

- `actor`
- `role`
- `goal`
- `score`
- `scores`
- `target`
- `reason`

Example:

```json
{"type":"decision","time_sec":4.2,"actor":"NPC_01","role":"gatherer","goal":"water","score":0.82,"scores":{"food":0.31,"water":0.82,"resource":0.22},"target":"Water_03","reason":"thirst_high"}
```

### `interaction_complete`

Emitted when a target interaction changes actor or world state.

Required fields:

- `actor`
- `goal`
- `target`
- `duration_sec`
- `result`
- `delta`

Example:

```json
{"type":"interaction_complete","time_sec":9.7,"actor":"NPC_01","goal":"water","target":"Water_03","duration_sec":1.5,"result":"success","delta":{"thirst":-55}}
```

### `stuck`

Emitted when an actor has a target but is not making useful progress.

Required fields:

- `actor`
- `goal`
- `target`
- `stuck_seconds`
- `distance_to_target`
- `position`

### `reservation`

Emitted when a target reservation succeeds or fails.

Required fields:

- `actor`
- `goal`
- `target`
- `result`
- `reason`

### `frame_sample`

Emitted at a low frequency for performance analysis.

Required fields:

- `active_ai_count`
- `fps`
- `physics_fps`
- `frame_time_ms`
- `decision_count`
- `interaction_count`

## Summary Metrics

The parser should report at least:

- Total decisions
- Decisions by goal
- Average selected score
- Interaction completions by goal and result
- Stuck event count and max stuck seconds
- Reservation success/failure counts
- Average and worst frame time if samples exist

## Scoring Direction

Early loop score can be simple:

```text
score =
  interaction_successes * 10
  - stuck_events * 3
  - reservation_failures * 2
  - average_frame_time_ms_penalty
```

Keep scoring transparent. If the score is too clever, the loop will optimize confusing artifacts instead of gameplay.

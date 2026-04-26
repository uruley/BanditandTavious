# AI Loop Verification

## Visual Gate

Use this when changing scene layout, actor visuals, navigation, collision, or debug drawing.

Checklist:

1. Open the target scene in Godot.
2. Run the scene directly with F6 when possible.
3. Confirm agents spawn above the walkable surface.
4. Confirm visible target markers exist for food, water, and resources.
5. Watch at least one full goal cycle: select, move, interact, replan.
6. Check Godot errors and warnings before reporting completion.

## Headless Gate

Use this for repeatable behavior and loop-mode scoring.

Important machine rule:

- Always pass an explicit repo-local `--log-file`, for example `logs/godot_ai_headless.log`.
- The default Mono CLI log destination can crash before scene execution on this machine.

Example shape:

```powershell
godot --headless --path . --scene res://level/scenes/lyrasandbox.tscn --log-file .\logs\godot_ai_headless.log -- --ai-test --duration 60 --seed 1234
```

Use the actual Godot executable path configured on the machine if `godot` is not in `PATH`.

## Acceptance Gates

For Phase 1 collection AI:

- No script parse errors.
- Scene starts without fatal runtime errors.
- At least three AI actors spawn.
- At least one `decision` event per actor.
- At least one successful `interaction_complete` event in a short run.
- Stuck events are either absent or explained by logged follow-up.
- Frame samples exist if the change could affect performance.

For Loop Mode:

- Run the same seed before and after a change.
- Compare metric summaries, not vibes.
- Keep the changed file set bounded.
- Reject changes that improve one metric by breaking basic visible behavior.

## Suggested Artifacts

Write generated artifacts under `logs/`:

- `logs/ai_metrics.jsonl`
- `logs/ai_metrics_summary.json`
- `logs/godot_ai_headless.log`
- `logs/ai_loop_scoreboard.md`

Do not put large generated logs in `docs/ai/` or `docs/wiki/`. Distill only durable conclusions into memory or wiki files.

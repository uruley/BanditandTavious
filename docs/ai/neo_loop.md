# Neo Loop Mode

Related:
- [[current-state|Current State]]
- [[neo_goal|Neo Goal]]
- [[neo_scoreboard|Neo Scoreboard]]
- [[session-notes|Session Notes]]

## Purpose

Loop Mode is an optional, operator-triggered workflow for running Neo through a bounded series of small improvement loops toward one explicit goal.

Loop Mode is not the default repo behavior. It only starts when the user explicitly asks for it.

## Loop Steps

1. Read `docs/ai/current-state.md`
2. Read `docs/ai/neo_state.json`
3. Read `docs/ai/neo_goal.md`
4. Inspect only the project files relevant to the current goal
5. Propose one small change
6. Apply the change
7. Create a per-loop artifact under `logs/neo_loops/YYYYMMDD_HHMMSS_loop_N/`
8. Run `tools/neo_check.ps1`
9. Compare the result against `docs/ai/neo_scoreboard.md`
10. Keep or revert the change
11. Update `docs/ai/current-state.md` and `docs/wiki/*` only with durable lessons
12. Stop after `N` loops or when the goal is satisfied

## Operating Rules

- Keep each loop small enough to review and reason about.
- Prefer one reversible change per loop.
- Do not activate Loop Mode automatically on normal Codex or Gemini runs.
- Use `tools/neo_check.ps1` as the standard repo-health checkpoint between loop iterations.
- Use `tools/new_neo_loop_artifact.ps1` or `tools/neo_loop.ps1` to create replayable loop evidence.
- Keep memory concise. If a loop produces too much history, archive it instead of expanding current operational files.

## Suggested Command

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\neo_loop.ps1 -MaxLoops 3
```

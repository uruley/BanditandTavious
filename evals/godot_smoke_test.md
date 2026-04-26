# Godot Smoke Test

## Goal

Use this checklist for a quick runtime sanity pass after a small Neo loop change.

## Checklist

- [ ] Project opens without immediate script parse errors.
- [ ] `project.godot` still points at the expected main scene.
- [ ] The target scene launches.
- [ ] No new critical errors appear in the Godot console.
- [ ] The current task's main interaction path is still reachable.
- [ ] Any blockers found are reflected in `docs/ai/current-state.md` only if they are durable.

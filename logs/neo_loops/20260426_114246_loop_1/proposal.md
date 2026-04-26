# Neo Loop Proposal

- Created UTC: 2026-04-26T16:42:46Z
- Loop Index: 1
- Goal: Create a Lyra AI persistent memory log that survives restarting lyrasandbox
- Active Scene: res://level/scenes/lyrasandbox.tscn
- Recommended Next Loop: Verify two sequential lyrasandbox runs: first writes `user://lyra_ai_memory.json`, second loads it and logs `ai_memory_loaded`.

## Proposed Change

- Add a small `LyraAIMemoryStore` node created by `LyraAIPrototype`.
- Feed existing AI metric events into the memory store.
- Persist per-actor summaries and an append-only memory event log under `user://`.

## Expected Evidence

- Run 1 starts with zero actor memories and writes persistent memory.
- Run 2 loads six actor memories and emits `ai_memory_restored` events.
- The persisted memory JSON survives the process restart.

# Neo Loop Proposal

- Created UTC: 2026-04-26T16:30:34Z
- Loop Index: 1
- Goal: Capture visual proof that the Lyra AI character is visible
- Active Scene: res://level/scenes/lyrasandbox.tscn
- Recommended Next Loop: Register real live visual evidence for Lyra AI visibility, then run neo_check.ps1 with -GateProfileOverride lyra_visual.

## Proposed Change

- Capture a real runtime viewport image proving Lyra sandbox AI actors are visible.
- Register the image through `tools/register_neo_visual_evidence.ps1` so `lyra_visual` can evaluate manifest-backed evidence.

## Expected Evidence

- `logs/visual_evidence/*/manifest.json` records the scene and claim.
- `tools/neo_check.ps1 -GateProfileOverride lyra_visual` sees registered live visual evidence.

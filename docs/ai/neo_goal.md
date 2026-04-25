# Neo Goal

## Active Goal

- Goal: Improve the Lyra AI sandbox loop by expanding navigation, increasing successful interactions, and proving AI weapon pickup behavior through bounded headless loops.
- Status: Satisfied on 2026-04-25 after 30 valid headless loops plus a final 25-second comparison run.

## Constraints

- Keep changes small and reviewable.
- Prefer project facts over assumptions.
- Do not switch Loop Mode on unless explicitly requested by the user.
- Stop early if the goal is satisfied or if verification is blocked by tooling/runtime limits.

## Goal Completion Signals

- `tools/neo_check.ps1` still reports the expected main scene and required memory files.
- Headless Lyra AI metrics show more successful interactions than the pre-pass baseline.
- Headless Lyra AI metrics include successful `weapon` interactions.
- Stuck events are reduced enough to justify keeping the scoped changes, with remaining stuck cases documented as follow-up navigation work.

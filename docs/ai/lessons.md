# Lessons

Related:
- [[memory|AI Memory]]
- [[current-state|Current State]]
- [[session-notes|Session Notes]]

## Verified Patterns

- Do not assume the scene under investigation is the project main scene. Confirm `project.godot` and the actual scene open in the editor.
- For 3rd person shooter setups (Lyra style), the character body's horizontal rotation must be locked to the camera yaw for strafing.
- Spawn orientation: if a player spawns facing the camera, the root `CharacterBody3D` should be rotated 180 degrees on Y, or the `SpringArmOffset` can be rotated to manually re-align the viewpoint. Rotating the root is preferred for consistent forward math, but pivot-offsetting is a valid visual fix.
- A `CollisionShape3D` node can exist in the scene tree and still be nonfunctional if `disabled = true`.
- A Terrain3D node without a configured `data_directory` and region data should not be treated as a guaranteed walkable surface.
- For this project, generated AI context summaries from `codebase-md` are useful only as rough indexes, not as authoritative project memory.

## User Corrections To Preserve

- The goal is not just to patch immediate bugs but to build persistent memory and reusable workflow in the repo.
- When diagnosing “falling through the floor,” inspect the real active world setup, not only the player scene.
- The goal of NotebookLM research is a compounding Obsidian second brain, not a pile of standalone reports. Research results should update linked domain knowledge and project memory.
- When the user asks for bigger navigation, do not count larger generated nav rectangles as the whole answer. Add route behavior and metrics that prove actors actually traverse named locations.
- For the Lyra AI loop, goal selection is not enough. Verify the complete lifecycle: goal picked, task started, task completed or failed with a reason, state/reservations cleaned up, and the actor moves on to the next useful goal.
- Use headless Godot loops as the default AI verification path, but use screenshots or windowed/editor captures for visible claims such as building appearance, weapon alignment, animation state, terrain/nav visibility, or UI state.

## Process Corrections

- Do not await `RenderingServer.frame_post_draw` or assume viewport screenshots are available in Godot headless runs. Check `DisplayServer.get_name()` and use a bounded watchdog so verification cannot hang indefinitely.
- For repeated Godot headless metrics, avoid reusing a single JSONL path unless the file is explicitly removed before writing. Batch loops exposed stale null/trailing bytes in `logs/ai_metrics.jsonl`; use unique `--metrics-path` values for loop artifacts.
- For runtime-spawned AI pickups, avoid placing the target directly on generated nav quad edges. A pickup can look reachable but repeatedly make `NavigationAgent3D` stop short; place the interactable inside the nav cell or verify with same-seed loop metrics.
- Generated nav can overpromise routes through real sandbox collision. When a far target creates a repeat stuck point, use fixed-seed target breakdowns and add reach filters or route waypoints instead of assuming a larger nav mesh is enough.
- Waypoint navigation is only real after `route_visit` metrics prove arrival. Decision logs that merely select a waypoint do not prove navigation; verify visits, distinct waypoint names, and stuck counts.
- Lyra AI headless loop runs must launch `res://level/scenes/lyrasandbox.tscn` explicitly. Launching the project main scene (`Sandbox.tscn`) will not start `LyraAIPrototype` metrics and can look like a hung AI run.
- Build interactions need a larger acceptance radius than pickup/resource interactions on the hand-authored sandbox nav grid. The first build site made haulers stop 3.5-4.1m short until `build_distance` was raised to `4.5`.
- Scout patrol lanes should match reachable corridors. Forcing every scout through the same crossing produced late route stuck events; lane-specific routes plus a route-visit priority cap produced clean final metrics.
- For standalone character test scenes, copy the proven third-person camera rig pattern from `level/scenes/player.tscn` before treating the setup as ready.
- Do not change `project.godot` main scene as a convenience for testing without explicit user approval; prefer `F6` on the target scene or ask first.
- When menu buttons stop responding, inspect overlapping sibling `Control` nodes first. Hidden children under a still-visible parent `Control` can leave a mouse-blocking overlay over the menu.
- Avoid parallelizing dependent CLI steps like `init`, `scan`, and `generate` when later steps require files produced by earlier steps.
- On Windows, force UTF-8 output when running tooling that prints Unicode through Rich if console encoding issues appear.
- For Godot scene debugging, verify the saved `.tscn` text when MCP property reads and live editor state disagree. Do not call a scene fixed until the serialized scene or a recreated replacement scene clearly contains the intended camera/light/layout.
- After adding new exported script properties, inspect the `.tscn` diff if using MCP scene property edits; the editor can serialize unintended `null` overrides that defeat script defaults.
- Do not integrate a tutorial/video weapon system into a large multiplayer scene first. Prove pickup/equip/fire in an isolated test scene with one player body and one pickup before wiring `lyrasandbox.tscn` or `Sandbox.tscn`.
- Keep pickup flags semantically separate: `auto_pickup` controls walk-over pickup, while `consume_on_pickup` controls whether a successfully equipped pickup disappears.
- Do not leave raw weapon visual nodes beside pickup scenes in a test level. If the player can see a gun-shaped mesh that is not in `weapon_pickups`, interaction testing becomes misleading.
- Do not solve per-gun alignment by moving the player, skeleton, or animation. The character gets one stable `WeaponMaster` hand socket; individual weapon meshes get their own offsets in `WeaponResource`.
- In multiplayer scenes, keep `player_scene` and `MultiplayerSpawner._spawnable_scenes` aligned when swapping the runtime player scene, or host/client spawn behavior can drift.
- When adapting a new imported character scene, inspect the live `AnimationPlayer` clip list first. Do not assume robot-era names like `Run` or `Fall` exist on the new asset.
- When replacing a multiplayer player body's scene graph, update `MultiplayerSynchronizer` to replicate the visible body's `AnimationPlayer`, not the old hidden body's animation node.
- If Godot keeps serving a stale cached scene after a major `.tscn` rebuild, bind the runtime to a new scene path and verify by opening that new path in the editor instead of trusting the old resource cache.
- When an imported character faces sideways relative to the controller, correct the visual body's yaw in the body adapter and initial body transform, not by rotating the whole player root or camera rig.
- When adapting Lyra-style visuals into the multiplayer player, point `_body` at the direct visual root (`UAL1_Standard`) and keep wrapper nodes out of the control path unless they solve a concrete runtime problem.
- If there is already a proven working character scene like `Bachtavious.tscn`, prefer instancing that exact scene into the multiplayer player instead of rebuilding an equivalent visual wrapper from imported assets.
- When a standalone character scene already works, match its controller and camera contract first. Copying only the mesh scene into multiplayer is not enough if the working behavior actually lives in a different root script.
- For vault/mantle placement, do not use raw ledge hit Y as the final `CharacterBody3D` origin. Compute and apply the current origin-to-floor offset, or the character can finish the animation hovering above the obstacle.
- Do not stack manual transform tween displacement on top of root-motion clips (`*_RM`) without explicitly routing root motion into physics; this desyncs mesh and collision. Use an `AnimationTree` in manual mode and apply root-motion delta through `CharacterBody3D.move_and_slide()` for climb states.
- Root-motion clips can report near-zero displacement depending on track setup or clip content; vault logic should detect stalled root motion and fall back to tween traversal to avoid wall-hang states.
- Keep scanner ray reach aligned with obstacle scale. Short 1m forward checks against larger CSG hurdles cause inconsistent vault starts and climb hangs.
- In traversal states, avoid mixed movement authority (physics velocity plus transform tweens) at the same time. Use one authority and guard finish callbacks to prevent double-completion races.
- For research-agent style iteration, do not rely on single manual runs. Use a scripted headless multi-cycle loop that emits machine-readable summaries and explicit gap signals after each cycle.
- Do not give a gameplay fix a “green light” without runtime verification evidence: launch scene, inspect logs, capture screenshot, then stop/kill the run session.

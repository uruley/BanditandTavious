# Life System

Related:
- [[index|Wiki Index]]
- [[ai_systems|AI Systems]]
- [[persistent_sandbox_ai|Persistent Sandbox AI Master Plan]]
- [[weapon_system|Modular Weapon System]]
- [[multiplayer|Multiplayer]]
- [[../ai/neo_goal_sheet|Neo Goal Sheet]]

## Purpose

The life system is the next core gameplay spine after movement, weapons, AI goals, and memory. It should make damage, death, downed state, recovery, revive, respawn, and AI memory events consistent across players and NPCs.

## Current Audit

There is no shared life-system spine yet.

Existing fragments:

- `level/scripts/player.gd` has `take_damage(_amount, _from_id)` but it immediately respawns the stock player instead of tracking health, downed state, death, or recovery.
- `level/scripts/bachtavious_multiplayer_player.gd` can fire projectiles through the modular weapon path, but it does not expose `take_damage` or a health state.
- `level/scripts/lyra_ai_actor.gd` can choose combat, fire weapons, and log shots, but Lyra AI actors do not yet have health, downed, death, recovery, or revive behavior.
- `level/scripts/lyra_ai_combat_target.gd` has a local `max_health`, `health`, `is_alive()`, `take_damage()`, and `reset()`, but this logic is isolated to target dummies.
- `level/scripts/destructible.gd` and `level/scripts/animated_destructible.gd` each define their own `health`, `take_damage()`, and `destroy()` path for world props.
- `level/scripts/bullet.gd` calls `take_damage(damage, shooter_id)`, while `simple_projectile.gd` calls `take_damage(damage)`. Future shared damage handling should tolerate both signatures or route all projectiles through a shared damage payload.
- `WeaponResource` already stores weapon damage, so the weapon system has the data needed to drive shared health.

## Smallest Shared Spine

Create one reusable `LifeComponent` node before adding deeper combat AI.

Suggested path:

- `res://level/scripts/components/life_component.gd`

Minimum API:

- `take_damage(amount: float, source: Node = null, context: Dictionary = {}) -> Dictionary`
- `heal(amount: float, source: Node = null, context: Dictionary = {}) -> Dictionary`
- `revive(source: Node = null, context: Dictionary = {}) -> Dictionary`
- `recover(source: Node = null, context: Dictionary = {}) -> Dictionary`
- `kill(source: Node = null, context: Dictionary = {}) -> Dictionary`
- `reset_life() -> void`
- `is_alive() -> bool`
- `is_downed() -> bool`
- `is_dead() -> bool`

Minimum exported state:

- `max_health`
- `health`
- `downed_threshold`
- `allow_downed_state`
- `auto_recover_seconds`
- `death_on_zero_health`
- `faction`
- `actor_id`

Minimum signals:

- `damaged(event)`
- `healed(event)`
- `downed(event)`
- `died(event)`
- `revived(event)`
- `recovered(event)`
- `respawned(event)`

Minimum event fields:

- `type`
- `actor`
- `actor_role`
- `faction`
- `amount`
- `health`
- `max_health`
- `source`
- `source_faction`
- `cause`
- `position`
- `run_id`

## First Implementation Slice

Start with Lyra AI actors and Bachtavious, not the whole project.

1. Add `LifeComponent` as a child node on runtime Lyra AI actors.
2. Add the same component to `lyra_player_clean.tscn` / `BachtaviousPlayer`.
3. Bridge `take_damage()` on actor/player scripts to the component so existing bullets/projectiles still work.
4. Have `LifeComponent` log `life_damaged`, `life_downed`, `life_died`, `life_recovered`, and `life_revived` through the existing Lyra metrics path when available.
5. Make Lyra AI stop active goals when downed/dead.
6. Add one simple recovery rule: downed actors auto-recover after a short timer, or stay down if `auto_recover_seconds <= 0`.
7. Add one headless test scene or `lyrasandbox` test flag that damages a Lyra actor and proves the events appear in JSONL metrics.

Do not migrate destructibles first. They can keep their `destroy()` behavior until living actors have a stable lifecycle.

## AI Behavior Hooks

Once the component exists, AI should use life facts as blackboard inputs:

- self health low -> retreat, seek help, or stop combat
- ally downed -> revive/help goal
- enemy downed/dead -> stop wasting shots and choose a new goal
- repeated damage from a source -> memory/fear/aggression event
- death/revive/recovery -> durable memory event

## Persistence Hooks

The existing Lyra memory store should eventually summarize life events:

- damage taken count
- last attacker
- last damage cause
- downed count
- death count
- revive count
- recovery count
- dangerous target or location

This makes health events useful for Neo's second-brain loop and for later SQLite world-state persistence.

## Acceptance For First Life-System Loop

The first implementation loop should pass only if:

- a Lyra AI actor can receive damage through the same public `take_damage()` path projectiles already expect
- metrics contain `life_damaged`
- either `life_downed` or `life_died` is emitted when health crosses the configured threshold
- the actor stops normal goal execution while downed/dead
- `tools/neo_check.ps1` still passes after the verification run

Visual proof is not required for the first headless slice. Visual proof becomes required once downed/death animations, revive interactions, or UI health bars are claimed.

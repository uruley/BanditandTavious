# AI Patterns for Godot 4

## Behavior Tree Tasks (LimboAI Style)

### BTAwaitAnimation
Use this to synchronize logic with physical abilities.
```gdscript
extends BTAction

@export var anim_name: StringName
@export var animation_player_var: StringName = &"animation_player"

func _tick(delta: float) -> Status:
	var ap: AnimationPlayer = blackboard.get_var(animation_player_var)
	if not ap.is_playing() or ap.current_animation != anim_name:
		return SUCCESS
	return RUNNING
```

### BTAttackAction
```gdscript
extends BTAction

func _tick(delta: float) -> Status:
	var target = blackboard.get_var(&"target_actor")
	if not is_instance_valid(target):
		return FAILURE

	agent.perform_attack(target)
	return SUCCESS
```

## Weapon Systems

### AttackComponent
Use composition to add weapon capabilities.
```gdscript
class_name AttackComponent extends Node3D

@export var damage: int = 10
@export var attack_range: float = 2.0
@export var cooldown: float = 1.0

func try_attack(target: Node3D):
	# check cooldown and range
	# spawn projectile or apply hitscan damage
```

### Raycast Perception
Use raycasts for Line of Sight (LOS) checks before attacking.
```gdscript
func can_see(target: Node3D) -> bool:
	raycast.target_position = raycast.to_local(target.global_position)
	raycast.force_raycast_update()
	return raycast.get_collider() == target
```

## Utility Scoring Patterns

### Considerations
Normalize inputs to 0.0 - 1.0.

```gdscript
func get_hunger_score() -> float:
	return clamp(hunger / max_hunger, 0.0, 1.0)

func get_threat_score() -> float:
	var enemies = get_tree().get_nodes_in_group("enemies")
	# ... calculate distance to nearest ...
	return 1.0 - clamp(dist / max_sense_range, 0.0, 1.0)
```

## GOAP Patterns

### World State
Use a Dictionary for the Blackboard:
```gdscript
var world_state = {
	"has_weapon": true,
	"can_see_enemy": false,
	"enemy_is_dead": false,
	"is_at_objective": false
}
```

### Action Definition
```gdscript
class_name MoveToObjective extends GoapAction
func get_preconditions() -> Dictionary: return {"can_see_enemy": false}
func get_effects() -> Dictionary: return {"is_at_objective": true}
func get_cost() -> float: return 1.0
```

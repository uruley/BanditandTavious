extends CharacterBody3D

## Starting behavior — Qwen3 will rewrite this each run.

const GRAVITY := 18.0
const SPEED := 4.0

var target: Node3D = null


func _ready() -> void:
	add_to_group("karpathy_agent")


func _physics_process(delta: float) -> void:
	velocity.y -= GRAVITY * delta

	if not target or not is_instance_valid(target) or not target.visible:
		target = _find_nearest_pickup()

	if target and is_instance_valid(target):
		var dir := target.global_position - global_position
		dir.y = 0.0
		if dir.length() > 0.1:
			dir = dir.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


func _find_nearest_pickup() -> Node3D:
	var nearest: Node3D = null
	var best := INF
	for pickup in get_tree().get_nodes_in_group("pickup"):
		if not pickup.visible:
			continue
		var d := global_position.distance_to(pickup.global_position)
		if d < best:
			best = d
			nearest = pickup
	return nearest

extends CharacterBody3D

const GRAVITY := 18.0
const CAPSULE_HEIGHT := 1.8
const CAPSULE_RADIUS := 0.45
const DEFEND_RANGE := 7.0
const FOLLOW_DISTANCE := 2.2
const MIN_MOVE_DIST := 0.25

@export var move_speed: float = 3.4
@export var detection_range: float = 8.0
@export var wander_radius: float = 2.0
@export var body_color: Color = Color(0.24, 0.55, 0.9, 1.0)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var home_position: Vector3
var target_point: Vector3
var target_actor: CharacterBody3D
var player_node: Node3D
var retarget_timer: float = 0.0


func _ready() -> void:
	home_position = global_position
	target_point = home_position
	_configure_visuals()
	add_to_group("bandit_ai_actor")
	add_to_group("bandit_ai_companion")
	retarget_timer = randf_range(0.1, 0.45)


func _physics_process(delta: float) -> void:
	retarget_timer -= delta
	velocity.y -= GRAVITY * delta

	if retarget_timer <= 0.0:
		_refresh_player()
		_pick_target()
		retarget_timer = 0.4

	var dir := _move_direction()
	velocity.x = dir.x
	velocity.z = dir.z

	if dir.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)

	move_and_slide()


func _refresh_player() -> void:
	if player_node and is_instance_valid(player_node):
		return
	var players := get_tree().get_nodes_in_group("players")
	player_node = players[0] as Node3D if players.size() > 0 else null


func _pick_target() -> void:
	var anchor: Node3D = player_node if player_node and is_instance_valid(player_node) else self
	target_actor = _nearest_around(anchor, ["bandit_ai_enemy"], DEFEND_RANGE)

	if target_actor:
		target_point = target_actor.global_position
	elif player_node and is_instance_valid(player_node):
		target_actor = null
		var angle := Time.get_ticks_msec() * 0.0015
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * FOLLOW_DISTANCE
		target_point = player_node.global_position + offset
	else:
		target_actor = null
		if global_position.distance_to(target_point) < 1.0:
			_wander()


func _move_direction() -> Vector3:
	var flat := Vector3(target_point.x, global_position.y, target_point.z)
	var to := flat - global_position
	var dist := to.length()
	if dist < MIN_MOVE_DIST:
		return Vector3.ZERO
	if target_actor and dist < 1.5:
		var perp := Vector3(-to.z, 0.0, to.x).normalized()
		return perp * move_speed * 0.7
	return to.normalized() * move_speed


func _wander() -> void:
	target_point = home_position + Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)


func _configure_visuals() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.height = CAPSULE_HEIGHT
	capsule.radius = CAPSULE_RADIUS
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var mesh := CapsuleMesh.new()
	mesh.height = CAPSULE_HEIGHT
	mesh.radius = CAPSULE_RADIUS
	body_mesh.mesh = mesh
	body_mesh.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.82
	body_mesh.material_override = mat


func _nearest_around(anchor: Node3D, groups: Array[String], radius: float) -> CharacterBody3D:
	var nearest: CharacterBody3D
	var best := radius
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			var c := node as CharacterBody3D
			if c == null:
				continue
			var d := anchor.global_position.distance_to(c.global_position)
			if d < best:
				best = d
				nearest = c
	return nearest


func get_ai_snapshot() -> Dictionary:
	var state: String
	if target_actor:
		state = "defend"
	elif player_node and is_instance_valid(player_node):
		state = "escort"
	else:
		state = "wander"
	return {
		"name": name,
		"role": "companion",
		"position": global_position,
		"state": state,
		"target": target_actor.name if target_actor else (player_node.name if player_node and is_instance_valid(player_node) else ""),
	}

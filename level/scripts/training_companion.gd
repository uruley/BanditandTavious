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
@export var shoot_cooldown: float = 1.2
@export var shoot_spread: float = 0.06
@export var body_color: Color = Color(0.2, 0.45, 0.85, 1.0)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var home_position: Vector3
var target_point: Vector3
var target_actor: CharacterBody3D
var player_node: Node3D
var retarget_timer: float = 0.0
var shoot_timer: float = 0.0

var shots_fired: int = 0
var shots_hit: int = 0
var pickups_collected: int = 0
var time_defending: float = 0.0


func _ready() -> void:
	home_position = global_position
	target_point = home_position
	_configure_visuals()
	add_to_group("bandit_ai_actor")
	add_to_group("bandit_ai_companion")
	add_to_group("training_agent")
	retarget_timer = randf_range(0.1, 0.45)


func _physics_process(delta: float) -> void:
	retarget_timer -= delta
	shoot_timer -= delta
	velocity.y -= GRAVITY * delta

	if retarget_timer <= 0.0:
		_refresh_player()
		_pick_target()
		retarget_timer = 0.4

	if target_actor:
		time_defending += delta

	_try_shoot()

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
		target_point = player_node.global_position + Vector3(cos(angle), 0.0, sin(angle)) * FOLLOW_DISTANCE
	else:
		target_actor = null
		if global_position.distance_to(target_point) < 1.0:
			_wander()


func _try_shoot() -> void:
	if shoot_timer > 0.0 or target_actor == null:
		return
	shoot_timer = shoot_cooldown
	shots_fired += 1

	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0.0, 1.2, 0.0)
	var aim := target_actor.global_position + Vector3(0.0, 0.9, 0.0)
	aim += Vector3(randf_range(-shoot_spread, shoot_spread), 0.0, randf_range(-shoot_spread, shoot_spread)) * eye.distance_to(aim)

	var query := PhysicsRayQueryParameters3D.create(eye, aim)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit and hit.collider == target_actor:
		shots_hit += 1


func _move_direction() -> Vector3:
	var flat := Vector3(target_point.x, global_position.y, target_point.z)
	var to := flat - global_position
	var dist := to.length()
	if dist < MIN_MOVE_DIST:
		return Vector3.ZERO
	if target_actor and dist < 1.5:
		return Vector3(-to.z, 0.0, to.x).normalized() * move_speed * 0.7
	return to.normalized() * move_speed


func _wander() -> void:
	target_point = home_position + Vector3(randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius))


func collect_pickup() -> void:
	pickups_collected += 1


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


func get_fitness_score() -> float:
	var accuracy := float(shots_hit) / float(shots_fired) if shots_fired > 0 else 0.0
	return shots_hit * 10.0 + accuracy * 30.0 + pickups_collected * 10.0 + time_defending * 0.5


func reset_for_episode(params: Dictionary, spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	home_position = spawn_pos
	target_point = spawn_pos
	target_actor = null
	player_node = null
	shoot_timer = 0.0
	shots_fired = 0
	shots_hit = 0
	pickups_collected = 0
	time_defending = 0.0
	for key in params:
		set(key, params[key])
	_configure_visuals()


func get_ai_snapshot() -> Dictionary:
	var accuracy := float(shots_hit) / float(shots_fired) if shots_fired > 0 else 0.0
	return {"name": name, "role": "companion", "position": global_position,
		"shots_fired": shots_fired, "shots_hit": shots_hit, "accuracy": accuracy, "pickups": pickups_collected}
